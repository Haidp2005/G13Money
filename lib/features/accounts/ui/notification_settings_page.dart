import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/language_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;

  bool _transactionAlertsEnabled = true;
  bool _budgetThresholdAlertsEnabled = true;
  double _budgetThresholdPercent = 80;

  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final uid = AuthService.currentUserId;
    if (uid == null) {
      setState(() {
        _isLoading = false;
        _error = LanguageService.tr(
          vi: 'Bạn chưa đăng nhập',
          en: 'You are not logged in',
        );
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .get();

      final data = snapshot.data() ?? <String, dynamic>{};
      final rawThreshold = (data['budgetAlertThresholdPercent'] as num?)?.toDouble();

      setState(() {
        _transactionAlertsEnabled =
            (data['transactionAlerts'] as bool?) ?? true;
        _budgetThresholdAlertsEnabled =
            (data['budgetAlerts'] as bool?) ?? true;
        _budgetThresholdPercent = (rawThreshold == null)
            ? 80
          : rawThreshold.clamp(1, 100);
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _error = LanguageService.tr(
          vi: 'Không thể tải cài đặt thông báo',
          en: 'Could not load notification settings',
        );
      });
    }
  }

  Future<void> _savePreferences() async {
    final uid = AuthService.currentUserId;
    if (uid == null) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('preferences')
          .set({
        'transactionAlerts': _transactionAlertsEnabled,
        'budgetAlerts': _budgetThresholdAlertsEnabled,
        'budgetAlertThresholdPercent': _budgetThresholdPercent.round().clamp(1, 100),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LanguageService.tr(
              vi: 'Đã lưu cài đặt thông báo',
              en: 'Notification settings saved',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = LanguageService.tr(
          vi: 'Lưu cài đặt thất bại',
          en: 'Failed to save settings',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LanguageService.tr(
            vi: 'Cài đặt thông báo',
            en: 'Notification settings',
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Card(
                    child: SwitchListTile(
                      title: Text(
                        LanguageService.tr(
                          vi: 'Thông báo giao dịch mới',
                          en: 'New transaction notifications',
                        ),
                      ),
                      subtitle: Text(
                        LanguageService.tr(
                          vi: 'Nhận thông báo khi có giao dịch mới được tạo',
                          en: 'Notify when a new transaction is created',
                        ),
                      ),
                      value: _transactionAlertsEnabled,
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setState(() {
                                _transactionAlertsEnabled = value;
                              });
                            },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              LanguageService.tr(
                                vi: 'Cảnh báo hạn mức ngân sách',
                                en: 'Budget limit alerts',
                              ),
                            ),
                            subtitle: Text(
                              LanguageService.tr(
                                vi: 'Cảnh báo khi chi tiêu vượt quá ngưỡng bạn chọn',
                                en: 'Alert when spending exceeds your chosen threshold',
                              ),
                            ),
                            value: _budgetThresholdAlertsEnabled,
                            onChanged: _isSaving
                                ? null
                                : (value) {
                                    setState(() {
                                      _budgetThresholdAlertsEnabled = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 6),
                          Text(
                            LanguageService.tr(
                              vi: 'Ngưỡng cảnh báo: ${_budgetThresholdPercent.round()}%',
                              en: 'Alert threshold: ${_budgetThresholdPercent.round()}%',
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          Slider(
                            min: 1,
                            max: 100,
                            divisions: 99,
                            label: '${_budgetThresholdPercent.round()}%',
                            value: _budgetThresholdPercent,
                            onChanged: (!_budgetThresholdAlertsEnabled || _isSaving)
                                ? null
                                : (value) {
                                    setState(() {
                                      _budgetThresholdPercent = value;
                                    });
                                  },
                          ),
                          Text(
                            LanguageService.tr(
                              vi: 'Ví dụ: 80% nghĩa là sẽ cảnh báo khi đã dùng 80% ngân sách.',
                              en: 'Example: 80% means alert when 80% of budget is used.',
                            ),
                            style: TextStyle(fontSize: 12, color: scheme.outline),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  FilledButton.icon(
                    onPressed: _isSaving ? null : _savePreferences,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      LanguageService.tr(vi: 'Lưu cài đặt', en: 'Save settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
