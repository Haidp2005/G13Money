import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  SupabaseStorageService._();

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool _initialized = false;

  static bool get isConfigured =>
      _url.trim().isNotEmpty && _anonKey.trim().isNotEmpty;

  static Future<void> initialize() async {
    if (_initialized || !isConfigured) {
      _initialized = _initialized || !isConfigured;
      return;
    }

    await Supabase.initialize(url: _url, anonKey: _anonKey);
    _initialized = true;
  }

  static Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
  }) async {
    _ensureReady();

    final bucket = Supabase.instance.client.storage.from('avatars');
    final filePath = '$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';

    await bucket.uploadBinary(
      filePath,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    return bucket.getPublicUrl(filePath);
  }

  static Future<List<String>> uploadTransactionImages({
    required String uid,
    required String transactionId,
    required List<Uint8List> images,
  }) async {
    _ensureReady();
    if (images.isEmpty) return const <String>[];

    final bucket = Supabase.instance.client.storage.from('transaction-images');
    final urls = <String>[];

    for (var i = 0; i < images.length; i++) {
      final filePath =
          '$uid/$transactionId/image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      await bucket.uploadBinary(
        filePath,
        images[i],
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
      urls.add(bucket.getPublicUrl(filePath));
    }

    return urls;
  }

  static Future<void> deleteAvatarByPublicUrl(String publicUrl) async {
    await deleteFilesByPublicUrls(
      bucketName: 'avatars',
      publicUrls: <String>[publicUrl],
    );
  }

  static Future<void> deleteTransactionImagesByPublicUrls(
    List<String> publicUrls,
  ) async {
    await deleteFilesByPublicUrls(
      bucketName: 'transaction-images',
      publicUrls: publicUrls,
    );
  }

  static Future<void> deleteFilesByPublicUrls({
    required String bucketName,
    required List<String> publicUrls,
  }) async {
    _ensureReady();
    if (publicUrls.isEmpty) return;

    final bucket = Supabase.instance.client.storage.from(bucketName);
    final paths = <String>[];

    for (final rawUrl in publicUrls) {
      final path = _extractPathFromPublicUrl(
        bucketName: bucketName,
        publicUrl: rawUrl,
      );
      if (path != null && path.isNotEmpty) {
        paths.add(path);
      }
    }

    if (paths.isEmpty) return;
    await bucket.remove(paths);
  }

  static String? _extractPathFromPublicUrl({
    required String bucketName,
    required String publicUrl,
  }) {
    final raw = publicUrl.trim();
    if (raw.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(raw);
    if (uri == null) {
      return null;
    }

    final marker = '/storage/v1/object/public/$bucketName/';
    final path = uri.path;
    final markerIndex = path.indexOf(marker);
    if (markerIndex == -1) {
      return null;
    }

    final filePath = path.substring(markerIndex + marker.length);
    if (filePath.isEmpty) {
      return null;
    }

    return Uri.decodeComponent(filePath);
  }

  static void _ensureReady() {
    if (!isConfigured) {
      throw Exception(
        'Supabase chưa được cấu hình. Hãy chạy app với SUPABASE_URL và SUPABASE_ANON_KEY.',
      );
    }
    if (!_initialized) {
      throw Exception('Supabase chưa khởi tạo. Hãy khởi động lại app.');
    }
  }
}
