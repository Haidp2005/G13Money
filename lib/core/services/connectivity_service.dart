import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight connectivity checker that pings a known DNS host.
/// Does NOT require a third-party package – uses `dart:io` directly.
class ConnectivityService {
  ConnectivityService._();

  /// Quick connectivity probe: tries to look up `google.com`.
  /// Returns `true` when the device can reach the internet.
  static Future<bool> hasConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Global Riverpod provider that other widgets can watch / read.
final connectivityProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ConnectivityService.hasConnection();
});

/// Specific exception representing a lack of internet connectivity.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'OfflineException: No internet connection';
}
