import 'package:flutter/material.dart';

import '../../../core/services/language_service.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _feedbackCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _searchCtrl.text.trim().toLowerCase();
    final faqs = _allFaqs
        .where(
          (item) =>
              item.question.toLowerCase().contains(query) ||
              item.answer.toLowerCase().contains(query),
        )
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(LanguageService.tr(vi: 'Trợ giúp', en: 'Help Center')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: LanguageService.tr(
                vi: 'Tìm câu hỏi...',
                en: 'Search questions...',
              ),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            LanguageService.tr(vi: 'Câu hỏi thường gặp', en: 'Frequently asked questions'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          if (faqs.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                LanguageService.tr(
                  vi: 'Không tìm thấy kết quả phù hợp.',
                  en: 'No matching results found.',
                ),
                style: TextStyle(color: scheme.outline),
              ),
            )
          else
            ...faqs.map(
              (item) => Card(
                child: ExpansionTile(
                  title: Text(item.question),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item.answer,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            LanguageService.tr(vi: 'Liên hệ hỗ trợ', en: 'Contact support'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageService.tr(
                      vi: 'Email: support@g13money.app',
                      en: 'Email: support@g13money.app',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feedbackCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: LanguageService.tr(
                        vi: 'Nhập phản hồi của bạn...',
                        en: 'Enter your feedback...',
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () {
                        if (_feedbackCtrl.text.trim().isEmpty) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              LanguageService.tr(
                                vi: 'Đã gửi phản hồi thành công!',
                                en: 'Feedback sent successfully!',
                              ),
                            ),
                          ),
                        );
                        _feedbackCtrl.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.send_outlined),
                      label: Text(LanguageService.tr(vi: 'Gửi phản hồi', en: 'Send feedback')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_FaqItem> get _allFaqs => [
        _FaqItem(
          question: LanguageService.tr(
            vi: 'Làm sao để đổi mật khẩu?',
            en: 'How can I change my password?',
          ),
          answer: LanguageService.tr(
            vi: 'Vào Tài khoản → Bảo mật → nhập mật khẩu cũ và mật khẩu mới.',
            en: 'Go to Account → Security → enter old and new password.',
          ),
        ),
        _FaqItem(
          question: LanguageService.tr(
            vi: 'Làm sao để đổi ngôn ngữ ứng dụng?',
            en: 'How to change app language?',
          ),
          answer: LanguageService.tr(
            vi: 'Vào Tài khoản → Ngôn ngữ và chọn Tiếng Việt hoặc English.',
            en: 'Go to Account → Language and choose Vietnamese or English.',
          ),
        ),
        _FaqItem(
          question: LanguageService.tr(
            vi: 'Làm sao để bật giao diện tối?',
            en: 'How to enable dark mode?',
          ),
          answer: LanguageService.tr(
            vi: 'Vào Tài khoản → Giao diện và chọn Tối.',
            en: 'Go to Account → Appearance and choose Dark.',
          ),
        ),
        _FaqItem(
          question: LanguageService.tr(
            vi: 'Vì sao tôi nhận cảnh báo ngân sách?',
            en: 'Why do I receive budget alerts?',
          ),
          answer: LanguageService.tr(
            vi: 'Hệ thống sẽ cảnh báo khi danh mục dùng từ 80% hạn mức trở lên.',
            en: 'The app alerts when a budget category reaches 80% or more.',
          ),
        ),
      ];
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
