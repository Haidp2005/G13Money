import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/services/language_service.dart';
import '../../shared/widgets/category_helper.dart';
import '../models/budget.dart';
import 'budget_form.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final List<Budget> _budgets = [
    Budget(
      id: 'budget-food',
      title: 'Ăn uống tháng 4',
      category: 'Ăn uống',
      limit: 3000000,
      spent: 1850000,
      date: DateTime(2026, 4, 15),
      color: CategoryHelper.colorFor('Ăn uống'),
      icon: CategoryHelper.iconFor('Ăn uống'),
    ),
    Budget(
      id: 'budget-transport',
      title: 'Di chuyển',
      category: 'Di chuyển',
      limit: 1200000,
      spent: 620000,
      date: DateTime(2026, 4, 15),
      color: CategoryHelper.colorFor('Di chuyển'),
      icon: CategoryHelper.iconFor('Di chuyển'),
    ),
    Budget(
      id: 'budget-shopping',
      title: 'Mua sắm cá nhân',
      category: 'Mua sắm',
      limit: 2500000,
      spent: 2350000,
      date: DateTime(2026, 4, 15),
      color: CategoryHelper.colorFor('Mua sắm'),
      icon: CategoryHelper.iconFor('Mua sắm'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final expandedHeaderHeight = (viewportHeight * 0.56).clamp(360.0, 520.0);
    final monthLabel = _monthLabel(DateTime.now());
    final totalSpent = _budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.spent,
    );
    final totalBudgetLimit = _budgets.fold<double>(
      0,
      (sum, budget) => sum + budget.limit,
    );
    final remainingBudgetLimit = totalBudgetLimit - totalSpent;
    final isLimitCritical =
        totalBudgetLimit > 0 && (remainingBudgetLimit / totalBudgetLimit) < 0.1;
    final totalIncome = 8500000.0;
    final daysRemaining = _daysRemainingInCurrentMonth();

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openBudgetForm(),
        icon: const Icon(Icons.add),
        label: Text(LanguageService.tr(vi: 'Thêm ngân sách', en: 'Add budget')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: expandedHeaderHeight,
            automaticallyImplyLeading: false,
            backgroundColor: scheme.primary,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _Header(
                scheme: scheme,
                monthLabel: monthLabel,
                totalIncome: totalIncome,
                totalSpent: totalSpent,
                remainingBudgetLimit: remainingBudgetLimit,
                isLimitCritical: isLimitCritical,
                daysRemaining: daysRemaining,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService.tr(vi: 'Danh sách ngân sách', en: 'Budget list'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      LanguageService.tr(
                        vi: '${_budgets.length} mục',
                        en: '${_budgets.length} items',
                      ),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 60),
            sliver: _budgets.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyState(onCreate: _openBudgetForm),
                  )
                : SliverList.separated(
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      return _BudgetCard(
                        budget: budget,
                        onEdit: () => _openBudgetForm(budget),
                        onDelete: () => _deleteBudget(budget),
                      );
                    },
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemCount: _budgets.length,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBudgetForm([Budget? budget]) async {
    final result = await showModalBottomSheet<Budget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: BudgetForm(initialBudget: budget),
      ),
    );

    if (result == null || !mounted) return;

    setState(() {
      final index = _budgets.indexWhere((item) => item.id == result.id);
      if (index >= 0) {
        _budgets[index] = result;
      } else {
        _budgets.insert(0, result);
      }
    });
  }

  void _deleteBudget(Budget budget) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LanguageService.tr(vi: 'Xóa ngân sách', en: 'Delete budget')),
        content: Text(
          LanguageService.tr(
            vi: 'Xóa "${budget.title}" khỏi danh sách ngân sách?',
            en: 'Remove "${budget.title}" from budget list?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LanguageService.tr(vi: 'Huỷ', en: 'Cancel')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(
                () => _budgets.removeWhere((item) => item.id == budget.id),
              );
            },
            child: Text(LanguageService.tr(vi: 'Xóa', en: 'Delete')),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme scheme;
  final String monthLabel;
  final double totalIncome;
  final double totalSpent;
  final double remainingBudgetLimit;
  final bool isLimitCritical;
  final int daysRemaining;

  const _Header({
    required this.scheme,
    required this.monthLabel,
    required this.totalIncome,
    required this.totalSpent,
    required this.remainingBudgetLimit,
    required this.isLimitCritical,
    required this.daysRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final overallProgress = totalIncome == 0
        ? 0.0
        : (totalSpent / totalIncome).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.tertiary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    LanguageService.tr(vi: 'Ngân sách', en: 'Budgets'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      monthLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                LanguageService.tr(
                  vi: 'Theo dõi hạn mức theo từng danh mục trong tháng hiện tại.',
                  en: 'Track spending limits by category for this month.',
                ),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ProgressRing(
                      progress: overallProgress,
                      progressColor: isLimitCritical
                          ? scheme.error
                          : Colors.white,
                      trackColor: Colors.white.withValues(alpha: 0.16),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      size: 168,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            label: LanguageService.tr(vi: 'Tổng thu', en: 'Income'),
                            value: _formatMoney(totalIncome),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryTile(
                            label: LanguageService.tr(vi: 'Tổng chi', en: 'Spent'),
                            value: _formatMoney(totalSpent),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryTile(
                            label: LanguageService.tr(vi: 'Ngày còn lại', en: 'Days left'),
                            value: '$daysRemaining',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _LimitSummaryCard(
                      remainingBudgetLimit: remainingBudgetLimit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitSummaryCard extends StatelessWidget {
  final double remainingBudgetLimit;

  const _LimitSummaryCard({required this.remainingBudgetLimit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        LanguageService.tr(
          vi: 'Hạn mức có thể chi: ${_formatMoney(remainingBudgetLimit)}',
          en: 'Available budget: ${_formatMoney(remainingBudgetLimit)}',
        ),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

int _daysRemainingInCurrentMonth() {
  final now = DateTime.now();
  final endOfMonth = DateTime(now.year, now.month + 1, 0);
  return endOfMonth.difference(now).inDays;
}

class _ProgressRing extends StatelessWidget {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final Color backgroundColor;
  final double size;

  const _ProgressRing({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.backgroundColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final percentText = '${(progress * 100).round()}%';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: animatedValue,
              progressColor: progressColor,
              trackColor: trackColor,
              backgroundColor: backgroundColor,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    percentText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'đã dùng',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _monthLabel(DateTime date) {
  return 'Thg ${date.month}/${date.year}';
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color trackColor;
  final Color backgroundColor;

  const _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.18;
    final ringRadius = radius - strokeWidth / 2 - 2;
    final gapAngle = math.pi * 0.34;
    final startAngle = math.pi / 2 - gapAngle / 2;
    final sweepAngle = -(2 * math.pi - gapAngle);
    final progressSweep = sweepAngle * progress.clamp(0.0, 1.0);

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = backgroundColor;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = progressColor;

    final rect = Rect.fromCircle(center: center, radius: ringRadius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);
    canvas.drawArc(rect, startAngle, progressSweep, false, progressPaint);

    if (progress < 1) {
      canvas.drawArc(
        rect,
        startAngle + progressSweep,
        sweepAngle - progressSweep,
        false,
        trackPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progressColor = budget.isOverBudget ? scheme.error : budget.color;

    return Card(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: budget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(budget.icon, color: budget.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        budget.category,
                        style: TextStyle(color: scheme.outline, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(LanguageService.tr(vi: 'Chỉnh sửa', en: 'Edit')),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(LanguageService.tr(vi: 'Xóa', en: 'Delete')),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: LanguageService.tr(vi: 'Đã chi', en: 'Spent'),
                    value: _formatMoney(budget.spent),
                    highlight: budget.isOverBudget,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatItem(
                    label: LanguageService.tr(vi: 'Hạn mức', en: 'Limit'),
                    value: _formatMoney(budget.limit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: budget.usageRatio,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LanguageService.tr(
                    vi: '${budget.usageLabel} đã dùng',
                    en: '${budget.usageLabel} used',
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
                Text(
                  budget.isOverBudget
                      ? LanguageService.tr(
                          vi: 'Vượt ${_formatMoney(budget.spent - budget.limit)}',
                          en: 'Exceeded ${_formatMoney(budget.spent - budget.limit)}',
                        )
                      : LanguageService.tr(
                          vi: 'Còn lại ${_formatMoney(budget.remaining)}',
                          en: 'Remaining ${_formatMoney(budget.remaining)}',
                        ),
                  style: TextStyle(color: scheme.outline, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatDate(budget.date),
              style: TextStyle(color: scheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatItem({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? scheme.errorContainer.withValues(alpha: 0.4)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: scheme.outline, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                size: 42,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LanguageService.tr(vi: 'Chưa có ngân sách nào', en: 'No budgets yet'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              LanguageService.tr(
                vi: 'Tạo ngân sách đầu tiên để theo dõi hạn mức chi tiêu theo danh mục.',
                en: 'Create your first budget to track category spending limits.',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.outline),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(LanguageService.tr(vi: 'Tạo ngân sách', en: 'Create budget')),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  final rounded = value.round();
  final isNegative = rounded < 0;
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final offset = digits.length - index;
    buffer.write(digits[index]);
    if (offset > 1 && offset % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${isNegative ? '-' : ''}${buffer.toString()} đ';
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
