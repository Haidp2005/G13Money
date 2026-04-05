import 'package:flutter/material.dart';

import '../../../core/services/language_service.dart';

/// A beautiful "no internet" error widget with a retry callback.
/// Can be used as a full-screen replacement or embedded inside a page.
class NoNetworkWidget extends StatelessWidget {
  const NoNetworkWidget({
    super.key,
    this.onRetry,
    this.compact = false,
  });

  /// Called when the user taps "Retry". If null, the retry button is hidden.
  final VoidCallback? onRetry;

  /// If true, renders a smaller inline version (e.g. inside a card).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (compact) {
      return _buildCompact(scheme);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Icon container ──
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 24),

            // ── Title ──
            Text(
              LanguageService.tr(
                vi: 'Không có kết nối mạng',
                en: 'No internet connection',
              ),
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // ── Subtitle ──
            Text(
              LanguageService.tr(
                vi: 'Vui lòng kiểm tra kết nối Internet của bạn và thử lại.',
                en: 'Please check your Internet connection and try again.',
              ),
              style: TextStyle(
                color: scheme.outline,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ── Retry button ──
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    LanguageService.tr(vi: 'Thử lại', en: 'Retry'),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: scheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              color: scheme.error,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LanguageService.tr(
                    vi: 'Không có kết nối mạng',
                    en: 'No internet connection',
                  ),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  LanguageService.tr(
                    vi: 'Kiểm tra Internet và thử lại.',
                    en: 'Check your Internet and retry.',
                  ),
                  style: TextStyle(
                    color: scheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: scheme.primary),
              tooltip: LanguageService.tr(vi: 'Thử lại', en: 'Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
