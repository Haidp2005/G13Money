import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/accounts/models/account.dart';
import '../../features/transactions/models/transaction.dart';

class AiFinanceService {
  AiFinanceService._();

  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash',
  );

  static bool get isConfigured => _apiKey.trim().isNotEmpty;

  static Future<String> generateAdvice({
    required List<MoneyTransaction> transactions,
    required List<Account> wallets,
  }) async {
    if (transactions.isEmpty) {
      return 'Bạn chưa có giao dịch để AI phân tích. Hãy thêm vài giao dịch rồi thử lại.';
    }

    final fallback = _buildFallbackAdvice(transactions, wallets);
    if (!isConfigured) {
      return '$fallback\n\nMẹo cấu hình AI: chạy app với --dart-define=GEMINI_API_KEY=<your_key> để nhận gợi ý thông minh hơn.';
    }

    final totalBalance = wallets.fold<double>(0, (sum, item) => sum + item.balance);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions
        .where((item) => !item.date.isBefore(monthStart))
        .toList(growable: false);

    final incomeMonth = monthTransactions
        .where((item) => item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseMonth = monthTransactions
        .where((item) => !item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final topExpenses = <String, double>{};
    for (final tx in monthTransactions.where((item) => !item.isIncome)) {
      topExpenses.update(tx.category, (value) => value + tx.amount,
          ifAbsent: () => tx.amount);
    }
    final top3 = topExpenses.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final prompt = StringBuffer()
      ..writeln('Bạn là cố vấn tài chính cá nhân cho người dùng Việt Nam.')
      ..writeln('Hãy trả lời bằng tiếng Việt, ngắn gọn, rõ ràng.')
      ..writeln('Đưa ra đúng 3 gợi ý hành động cụ thể, đánh số 1-3.')
      ..writeln('Mỗi gợi ý tối đa 2 câu, ưu tiên thực tế và dễ làm trong 7 ngày.')
      ..writeln('')
      ..writeln('Dữ liệu người dùng:')
      ..writeln('- Số dư hiện tại: ${totalBalance.toStringAsFixed(0)} VND')
      ..writeln('- Thu tháng này: ${incomeMonth.toStringAsFixed(0)} VND')
      ..writeln('- Chi tháng này: ${expenseMonth.toStringAsFixed(0)} VND')
      ..writeln('- Danh mục chi lớn nhất tháng này:')
      ..writeln(
          top3.take(3).map((e) => '  - ${e.key}: ${e.value.toStringAsFixed(0)} VND').join('\n'))
      ..writeln('- Tổng số giao dịch đã ghi nhận: ${transactions.length}')
      ..writeln('')
      ..writeln('Tạo lời khuyên tài chính cá nhân hoá ngay bây giờ.');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    try {
      final response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt.toString()}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return fallback;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = (data['candidates'] as List<dynamic>?) ?? const [];
      if (candidates.isEmpty) return fallback;

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = (content?['parts'] as List<dynamic>?) ?? const [];
      if (parts.isEmpty) return fallback;

      final text = (parts.first['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) return fallback;
      return text;
    } catch (_) {
      return fallback;
    }
  }

  static Future<String> chatWithAssistant({
    required String userMessage,
    required List<String> recentMessages,
    required List<MoneyTransaction> transactions,
    required List<Account> wallets,
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return 'Bạn hãy nhập câu hỏi tài chính để mình hỗ trợ.';
    }

    if (!isConfigured) {
      return _buildLocalChatFallback(trimmed, transactions, wallets);
    }

    final totalBalance = wallets.fold<double>(0, (sum, item) => sum + item.balance);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions
        .where((item) => !item.date.isBefore(monthStart))
        .toList(growable: false);
    final incomeMonth = monthTransactions
        .where((item) => item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseMonth = monthTransactions
        .where((item) => !item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final prompt = StringBuffer()
      ..writeln('Bạn là trợ lý tài chính cá nhân cho người dùng Việt Nam.')
      ..writeln('Trả lời bằng tiếng Việt, ngắn gọn, thực tế, ưu tiên hành động cụ thể.')
      ..writeln('Nếu câu hỏi cần số liệu thì dựa vào dữ liệu dưới đây.')
      ..writeln('')
      ..writeln('Bối cảnh tài chính hiện tại:')
      ..writeln('- Số dư hiện tại: ${totalBalance.toStringAsFixed(0)} VND')
      ..writeln('- Thu tháng này: ${incomeMonth.toStringAsFixed(0)} VND')
      ..writeln('- Chi tháng này: ${expenseMonth.toStringAsFixed(0)} VND')
      ..writeln('- Tổng giao dịch đã ghi nhận: ${transactions.length}')
      ..writeln('')
      ..writeln('Lịch sử hội thoại gần đây:')
      ..writeln(recentMessages.join('\n'))
      ..writeln('')
      ..writeln('Câu hỏi người dùng: $trimmed')
      ..writeln('Trả lời trực tiếp, rõ ràng.');

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    try {
      final response = await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt.toString()}
                  ]
                }
              ]
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _buildLocalChatFallback(trimmed, transactions, wallets);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = (data['candidates'] as List<dynamic>?) ?? const [];
      if (candidates.isEmpty) {
        return _buildLocalChatFallback(trimmed, transactions, wallets);
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = (content?['parts'] as List<dynamic>?) ?? const [];
      if (parts.isEmpty) {
        return _buildLocalChatFallback(trimmed, transactions, wallets);
      }

      final text = (parts.first['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) {
        return _buildLocalChatFallback(trimmed, transactions, wallets);
      }
      return text;
    } catch (_) {
      return _buildLocalChatFallback(trimmed, transactions, wallets);
    }
  }

  static String _buildLocalChatFallback(
    String userMessage,
    List<MoneyTransaction> transactions,
    List<Account> wallets,
  ) {
    final text = userMessage.toLowerCase();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions
        .where((item) => !item.date.isBefore(monthStart))
        .toList(growable: false);
    final incomeMonth = monthTransactions
        .where((item) => item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseMonth = monthTransactions
        .where((item) => !item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final balance = wallets.fold<double>(0, (sum, item) => sum + item.balance);

    if (text.contains('ngan sach') || text.contains('ngân sách')) {
      return 'Bạn nên đặt ngân sách theo 3 nhóm: Thiết yếu, Linh hoạt, Tiết kiệm. Với dữ liệu hiện tại, hãy đặt trần chi linh hoạt <= ${(expenseMonth * 0.3).toStringAsFixed(0)} VND/tháng và theo dõi hàng tuần.';
    }
    if (text.contains('tiet kiem') || text.contains('tiết kiệm')) {
      final suggested = incomeMonth > 0 ? incomeMonth * 0.15 : 0;
      return 'Gợi ý tiết kiệm: tự động trích ${suggested.toStringAsFixed(0)} VND ngay khi nhận thu nhập tháng này. Duy trì quỹ dự phòng tối thiểu 3 tháng chi tiêu thiết yếu.';
    }
    if (text.contains('chi tieu') || text.contains('chi tiêu')) {
      final ratio = incomeMonth <= 0 ? 1.0 : (expenseMonth / incomeMonth);
      return 'Tỷ lệ chi/thu hiện tại khoảng ${(ratio * 100).toStringAsFixed(0)}%. Nếu muốn an toàn tài chính hơn, hãy đưa tỷ lệ này về dưới 75% bằng cách cắt 1-2 danh mục chi linh hoạt.';
    }
    return 'Hiện tại số dư của bạn là ${balance.toStringAsFixed(0)} VND. Bạn có thể hỏi cụ thể hơn như: "Mình nên tiết kiệm bao nhiêu mỗi tháng?", "Danh mục nào đang chi quá tay?" hoặc "Lập ngân sách tuần này giúp mình".';
  }

  static String _buildFallbackAdvice(
    List<MoneyTransaction> transactions,
    List<Account> wallets,
  ) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthTransactions = transactions
        .where((item) => !item.date.isBefore(monthStart))
        .toList(growable: false);

    final incomeMonth = monthTransactions
        .where((item) => item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final expenseMonth = monthTransactions
        .where((item) => !item.isIncome)
        .fold<double>(0, (sum, item) => sum + item.amount);

    final topExpenses = <String, double>{};
    for (final tx in monthTransactions.where((item) => !item.isIncome)) {
      topExpenses.update(tx.category, (value) => value + tx.amount,
          ifAbsent: () => tx.amount);
    }

    String topCategoryLine = 'Bạn đang chi tiêu khá đều, tiếp tục duy trì kỷ luật tài chính.';
    if (topExpenses.isNotEmpty) {
      final top = topExpenses.entries.reduce((a, b) => a.value >= b.value ? a : b);
      topCategoryLine =
          'Danh mục chi cao nhất tháng này là ${top.key} (${top.value.toStringAsFixed(0)} VND), nên đặt hạn mức riêng cho mục này.';
    }

    final balance = wallets.fold<double>(0, (sum, item) => sum + item.balance);
    final ratio = incomeMonth <= 0 ? 1.0 : (expenseMonth / incomeMonth);

    final second = ratio > 0.85
        ? 'Tỷ lệ chi/thu đang ở mức ${(ratio * 100).toStringAsFixed(0)}%, hãy giảm ít nhất 10% chi tiêu linh hoạt trong tuần tới.'
        : 'Tỷ lệ chi/thu đang ở mức ${(ratio * 100).toStringAsFixed(0)}%, bạn có thể trích thêm 5-10% thu nhập để tiết kiệm.';

    final third = balance < 0
        ? 'Số dư hiện tại đang âm, ưu tiên trả các khoản nợ ngắn hạn trước khi mở rộng chi tiêu mới.'
        : 'Số dư hiện tại ổn định, bạn có thể tạo quỹ dự phòng bằng 3-6 tháng chi tiêu thiết yếu.';

    return '1. $topCategoryLine\n2. $second\n3. $third';
  }
}
