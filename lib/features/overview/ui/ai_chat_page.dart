import 'package:flutter/material.dart';

import '../../../core/services/ai_finance_service.dart';
import '../../accounts/models/account.dart';
import '../../transactions/models/transaction.dart';

class AiChatPage extends StatefulWidget {
  final List<MoneyTransaction> transactions;
  final List<Account> wallets;

  const AiChatPage({
    super.key,
    required this.transactions,
    required this.wallets,
  });

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      const _ChatMessage(
        isUser: false,
        text:
            'Xin chào! Mình là trợ lý tài chính AI. Bạn có thể hỏi về ngân sách, tiết kiệm, hoặc cách tối ưu chi tiêu.',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _sending = true;
      _messages.add(_ChatMessage(isUser: true, text: text));
      _inputController.clear();
    });

    _jumpToBottom();

    final recentMessages = _messages
        .take(12)
        .map((item) => '${item.isUser ? 'User' : 'AI'}: ${item.text}')
        .toList(growable: false);

    final reply = await AiFinanceService.chatWithAssistant(
      userMessage: text,
      recentMessages: recentMessages,
      transactions: widget.transactions,
      wallets: widget.wallets,
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(isUser: false, text: reply));
      _sending = false;
    });

    _jumpToBottom();
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat với AI tài chính'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AiFinanceService.isConfigured
                  ? 'AI đang kết nối model online. Hãy hỏi cụ thể để nhận tư vấn chính xác hơn.'
                  : 'AI đang ở chế độ local fallback. Thêm GEMINI_API_KEY để chat thông minh hơn.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final item = _messages[index];
                final bubbleColor = item.isUser
                    ? scheme.primary
                    : scheme.surfaceContainerHighest;
                final textColor = item.isUser
                    ? Colors.white
                    : scheme.onSurface;

                return Align(
                  alignment:
                      item.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.text,
                      style: TextStyle(color: textColor, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: giúp mình giảm chi tiêu tháng này',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: EdgeInsets.zero,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool isUser;
  final String text;

  const _ChatMessage({required this.isUser, required this.text});
}
