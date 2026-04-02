import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../shared/widgets/bottom_nav.dart';

class OverviewPage extends StatefulWidget {
	const OverviewPage({super.key});

	@override
	State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
	int _selectedPeriod = 1; // 0 = Tuần, 1 = Tháng

	// ── Data ──
	static const List<_WalletItem> _wallets = [
		_WalletItem(name: 'Chính', balance: '500,000 đ', icon: Icons.account_balance_wallet_rounded, color: Color(0xFF6C63FF)),
		_WalletItem(name: 'Tiền mặt', balance: '545,000 đ', icon: Icons.payments_rounded, color: Color(0xFFF09928)),
	];

	static const List<_TransactionItem> _recentTransactions = [
		_TransactionItem(
			title: 'Lương',
			date: '31 tháng 3 2026',
			amount: '+500,000',
			income: true,
			icon: Icons.account_balance_wallet_rounded,
			categoryColor: Color(0xFF6C63FF),
		),
		_TransactionItem(
			title: 'Ăn uống',
			date: '29 tháng 3 2026',
			amount: '-5,000',
			income: false,
			icon: Icons.restaurant_rounded,
			categoryColor: Color(0xFFFF6B6B),
		),
		_TransactionItem(
			title: 'Thu nhập khác',
			date: '29 tháng 3 2026',
			amount: '+500,000',
			income: true,
			icon: Icons.inventory_2_rounded,
			categoryColor: Color(0xFF2DCC5A),
		),
	];

	// Monthly chart data (last 6 months)
	static const List<_ChartData> _monthlyData = [
		_ChartData(label: 'T10', income: 8.5, expense: 5.2),
		_ChartData(label: 'T11', income: 7.0, expense: 6.8),
		_ChartData(label: 'T12', income: 9.2, expense: 4.5),
		_ChartData(label: 'T1', income: 6.5, expense: 7.0),
		_ChartData(label: 'T2', income: 8.0, expense: 3.2),
		_ChartData(label: 'T3', income: 10.0, expense: 0.05),
	];

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF0A0C10),
			body: SafeArea(
				child: SingleChildScrollView(
					physics: const BouncingScrollPhysics(),
					padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							_buildHeader(),
							const SizedBox(height: 24),
							_buildBalanceCard(),
							const SizedBox(height: 24),
							_buildReportSection(),
							const SizedBox(height: 24),
							_buildWalletSection(),
							const SizedBox(height: 24),
							_buildRecentTransactionsSection(),
						],
					),
				),
			),
			bottomNavigationBar: MoneyBottomNav(
				currentIndex: 0,
				onItemTap: (_) {},
				onAddTap: () {},
			),
		);
	}

	// ── Header ──
	Widget _buildHeader() {
		return Row(
			children: [
				Container(
					width: 44,
					height: 44,
					decoration: BoxDecoration(
						gradient: const LinearGradient(
							colors: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
						),
						borderRadius: BorderRadius.circular(14),
					),
					child: const Center(
						child: Text(
							'G',
							style: TextStyle(
								color: Colors.white,
								fontSize: 20,
								fontWeight: FontWeight.w800,
							),
						),
					),
				),
				const SizedBox(width: 12),
				const Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								'Xin chào! 👋',
								style: TextStyle(
									color: Color(0xFF8A909D),
									fontSize: 13,
									fontWeight: FontWeight.w500,
								),
							),
							SizedBox(height: 2),
							Text(
								'G13 Money',
								style: TextStyle(
									color: Colors.white,
									fontSize: 18,
									fontWeight: FontWeight.w700,
								),
							),
						],
					),
				),
				_headerIconButton(Icons.search_rounded),
				const SizedBox(width: 8),
				_headerIconButton(Icons.notifications_none_rounded),
			],
		);
	}

	Widget _headerIconButton(IconData icon) {
		return Container(
			width: 42,
			height: 42,
			decoration: BoxDecoration(
				color: const Color(0xFF1A1D24),
				borderRadius: BorderRadius.circular(13),
				border: Border.all(color: const Color(0xFF2A2E38), width: 1),
			),
			child: Icon(icon, color: const Color(0xFFBEC3CE), size: 22),
		);
	}

	// ── Balance Card ──
	Widget _buildBalanceCard() {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(22),
			decoration: BoxDecoration(
				gradient: const LinearGradient(
					colors: [Color(0xFF1E2A3A), Color(0xFF162033)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				borderRadius: BorderRadius.circular(24),
				border: Border.all(color: const Color(0xFF2A3A4E).withValues(alpha: 0.5), width: 1),
				boxShadow: [
					BoxShadow(
						color: const Color(0xFF6C63FF).withValues(alpha: 0.08),
						blurRadius: 30,
						offset: const Offset(0, 10),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							const Text(
								'Tổng số dư',
								style: TextStyle(
									color: Color(0xFF8A9BB5),
									fontSize: 14,
									fontWeight: FontWeight.w500,
								),
							),
							const SizedBox(width: 8),
							Container(
								padding: const EdgeInsets.all(4),
								decoration: BoxDecoration(
									color: const Color(0xFF2A3A4E),
									borderRadius: BorderRadius.circular(6),
								),
								child: const Icon(
									Icons.visibility_rounded,
									color: Color(0xFF8A9BB5),
									size: 14,
								),
							),
						],
					),
					const SizedBox(height: 10),
					const Text(
						'1,045,000 đ',
						style: TextStyle(
							color: Colors.white,
							fontSize: 32,
							fontWeight: FontWeight.w800,
							letterSpacing: -0.5,
						),
					),
					const SizedBox(height: 16),
					Row(
						children: [
							_balanceSummaryChip(
								icon: Icons.arrow_upward_rounded,
								label: 'Thu nhập',
								value: '1,000,000',
								color: Color(0xFF2DCC5A),
							),
							const SizedBox(width: 12),
							_balanceSummaryChip(
								icon: Icons.arrow_downward_rounded,
								label: 'Chi tiêu',
								value: '5,000',
								color: Color(0xFFFF6B6B),
							),
						],
					),
				],
			),
		);
	}

	Widget _balanceSummaryChip({
		required IconData icon,
		required String label,
		required String value,
		required Color color,
	}) {
		return Expanded(
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
				decoration: BoxDecoration(
					color: color.withValues(alpha: 0.1),
					borderRadius: BorderRadius.circular(14),
					border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
				),
				child: Row(
					children: [
						Container(
							padding: const EdgeInsets.all(4),
							decoration: BoxDecoration(
								color: color.withValues(alpha: 0.2),
								shape: BoxShape.circle,
							),
							child: Icon(icon, color: color, size: 14),
						),
						const SizedBox(width: 8),
						Expanded(
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Text(
										label,
										style: TextStyle(
											color: color.withValues(alpha: 0.8),
											fontSize: 11,
											fontWeight: FontWeight.w500,
										),
									),
									Text(
										value,
										style: TextStyle(
											color: color,
											fontSize: 13,
											fontWeight: FontWeight.w700,
										),
									),
								],
							),
						),
					],
				),
			),
		);
	}

	// ── Report Section with Bar Chart ──
	Widget _buildReportSection() {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				_sectionHeader(title: 'Báo cáo tháng này', action: 'Xem báo cáo'),
				const SizedBox(height: 14),
				_sectionCard(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							_buildPeriodSwitch(),
							const SizedBox(height: 20),
							// Summary row
							Row(
								children: [
									_reportLegend(color: const Color(0xFF6C63FF), label: 'Thu nhập'),
									const SizedBox(width: 20),
									_reportLegend(color: const Color(0xFFFF6B6B), label: 'Chi tiêu'),
								],
							),
							const SizedBox(height: 20),
							// Bar chart
							SizedBox(
								height: 200,
								child: BarChart(
									BarChartData(
										alignment: BarChartAlignment.spaceAround,
										maxY: 12,
										barTouchData: BarTouchData(
											enabled: true,
											touchTooltipData: BarTouchTooltipData(
												tooltipRoundedRadius: 12,
												getTooltipColor: (_) => const Color(0xFF2A2E38),
												tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
												getTooltipItem: (group, groupIndex, rod, rodIndex) {
													final data = _monthlyData[group.x];
													final isIncome = rodIndex == 0;
													return BarTooltipItem(
														'${isIncome ? "Thu" : "Chi"}: ${isIncome ? data.income : data.expense}tr',
														TextStyle(
															color: isIncome ? const Color(0xFF6C63FF) : const Color(0xFFFF6B6B),
															fontWeight: FontWeight.w600,
															fontSize: 12,
														),
													);
												},
											),
										),
										titlesData: FlTitlesData(
											show: true,
											bottomTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													getTitlesWidget: (value, meta) {
														final index = value.toInt();
														if (index >= 0 && index < _monthlyData.length) {
															return Padding(
																padding: const EdgeInsets.only(top: 8),
																child: Text(
																	_monthlyData[index].label,
																	style: const TextStyle(
																		color: Color(0xFF6B7280),
																		fontSize: 12,
																		fontWeight: FontWeight.w500,
																	),
																),
															);
														}
														return const SizedBox.shrink();
													},
													reservedSize: 28,
												),
											),
											leftTitles: AxisTitles(
												sideTitles: SideTitles(
													showTitles: true,
													reservedSize: 32,
													interval: 4,
													getTitlesWidget: (value, meta) {
														return Text(
															'${value.toInt()}tr',
															style: const TextStyle(
																color: Color(0xFF4A5060),
																fontSize: 10,
																fontWeight: FontWeight.w500,
															),
														);
													},
												),
											),
											topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
											rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
										),
										gridData: FlGridData(
											show: true,
											drawVerticalLine: false,
											horizontalInterval: 4,
											getDrawingHorizontalLine: (value) {
												return FlLine(
													color: const Color(0xFF1F2330),
													strokeWidth: 1,
													dashArray: [4, 4],
												);
											},
										),
										borderData: FlBorderData(show: false),
										barGroups: _monthlyData.asMap().entries.map((entry) {
											return BarChartGroupData(
												x: entry.key,
												barRods: [
													BarChartRodData(
														toY: entry.value.income,
														color: const Color(0xFF6C63FF),
														width: 14,
														borderRadius: const BorderRadius.only(
															topLeft: Radius.circular(6),
															topRight: Radius.circular(6),
														),
														backDrawRodData: BackgroundBarChartRodData(
															show: true,
															toY: 12,
															color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
														),
													),
													BarChartRodData(
														toY: entry.value.expense,
														color: const Color(0xFFFF6B6B),
														width: 14,
														borderRadius: const BorderRadius.only(
															topLeft: Radius.circular(6),
															topRight: Radius.circular(6),
														),
														backDrawRodData: BackgroundBarChartRodData(
															show: true,
															toY: 12,
															color: const Color(0xFFFF6B6B).withValues(alpha: 0.05),
														),
													),
												],
												barsSpace: 4,
											);
										}).toList(),
									),
									duration: const Duration(milliseconds: 500),
								),
							),
							const SizedBox(height: 16),
							// Summary totals
							Container(
								padding: const EdgeInsets.all(14),
								decoration: BoxDecoration(
									color: const Color(0xFF0F1118),
									borderRadius: BorderRadius.circular(14),
								),
								child: const Row(
									children: [
										Expanded(
											child: Column(
												children: [
													Text(
														'Tổng thu',
														style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
													),
													SizedBox(height: 4),
													Text(
														'1,000,000 đ',
														style: TextStyle(color: Color(0xFF6C63FF), fontSize: 15, fontWeight: FontWeight.w700),
													),
												],
											),
										),
										SizedBox(
											height: 30,
											child: VerticalDivider(color: Color(0xFF2A2E38), width: 1),
										),
										Expanded(
											child: Column(
												children: [
													Text(
														'Tổng chi',
														style: TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.w500),
													),
													SizedBox(height: 4),
													Text(
														'5,000 đ',
														style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 15, fontWeight: FontWeight.w700),
													),
												],
											),
										),
									],
								),
							),
						],
					),
				),
			],
		);
	}

	Widget _reportLegend({required Color color, required String label}) {
		return Row(
			children: [
				Container(
					width: 10,
					height: 10,
					decoration: BoxDecoration(
						color: color,
						borderRadius: BorderRadius.circular(3),
					),
				),
				const SizedBox(width: 6),
				Text(
					label,
					style: const TextStyle(
						color: Color(0xFF8A909D),
						fontSize: 12,
						fontWeight: FontWeight.w500,
					),
				),
			],
		);
	}

	// ── Wallet Section ──
	Widget _buildWalletSection() {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				_sectionHeader(title: 'Ví của tôi', action: 'Xem tất cả'),
				const SizedBox(height: 14),
				_sectionCard(
					child: Column(
						children: [
							..._wallets.asMap().entries.map((entry) {
								final isLast = entry.key == _wallets.length - 1;
								return Column(
									children: [
										_walletTile(entry.value),
										if (!isLast) const Divider(color: Color(0xFF1F2330), height: 1),
									],
								);
							}),
						],
					),
				),
			],
		);
	}

	// ── Recent Transactions Section ──
	Widget _buildRecentTransactionsSection() {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				_sectionHeader(title: 'Giao dịch gần đây', action: 'Xem tất cả'),
				const SizedBox(height: 14),
				_sectionCard(
					child: Column(
						children: _recentTransactions.asMap().entries.map((entry) {
							final isLast = entry.key == _recentTransactions.length - 1;
							return Column(
								children: [
									_transactionTile(entry.value),
									if (!isLast) const Divider(color: Color(0xFF1F2330), height: 1),
								],
							);
						}).toList(),
					),
				),
			],
		);
	}

	// ── Wallet Tile ──
	Widget _walletTile(_WalletItem item) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 14),
			child: Row(
				children: [
					Container(
						width: 48,
						height: 48,
						decoration: BoxDecoration(
							gradient: LinearGradient(
								colors: [item.color.withValues(alpha: 0.3), item.color.withValues(alpha: 0.1)],
								begin: Alignment.topLeft,
								end: Alignment.bottomRight,
							),
							borderRadius: BorderRadius.circular(14),
							border: Border.all(color: item.color.withValues(alpha: 0.2), width: 1),
						),
						child: Icon(item.icon, color: item.color, size: 24),
					),
					const SizedBox(width: 14),
					Expanded(
						child: Text(
							item.name,
							style: const TextStyle(
								color: Colors.white,
								fontSize: 15,
								fontWeight: FontWeight.w600,
							),
						),
					),
					Text(
						item.balance,
						style: const TextStyle(
							color: Colors.white,
							fontSize: 15,
							fontWeight: FontWeight.w700,
						),
					),
					const SizedBox(width: 8),
					const Icon(Icons.chevron_right_rounded, color: Color(0xFF4A5060), size: 20),
				],
			),
		);
	}

	// ── Transaction Tile ──
	Widget _transactionTile(_TransactionItem item) {
		final Color amountColor = item.income ? const Color(0xFF2DCC5A) : const Color(0xFFFF6B6B);

		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 14),
			child: Row(
				children: [
					Container(
						width: 48,
						height: 48,
						decoration: BoxDecoration(
							gradient: LinearGradient(
								colors: [
									item.categoryColor.withValues(alpha: 0.25),
									item.categoryColor.withValues(alpha: 0.08),
								],
								begin: Alignment.topLeft,
								end: Alignment.bottomRight,
							),
							borderRadius: BorderRadius.circular(14),
							border: Border.all(color: item.categoryColor.withValues(alpha: 0.2), width: 1),
						),
						child: Icon(item.icon, color: item.categoryColor, size: 22),
					),
					const SizedBox(width: 14),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									item.title,
									style: const TextStyle(
										color: Colors.white,
										fontSize: 15,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 3),
								Text(
									item.date,
									style: const TextStyle(
										color: Color(0xFF6B7280),
										fontSize: 12,
									),
								),
							],
						),
					),
					Text(
						item.amount,
						style: TextStyle(
							color: amountColor,
							fontSize: 15,
							fontWeight: FontWeight.w700,
						),
					),
				],
			),
		);
	}

	// ── Period Switch ──
	Widget _buildPeriodSwitch() {
		return Container(
			height: 44,
			padding: const EdgeInsets.all(3),
			decoration: BoxDecoration(
				color: const Color(0xFF0F1118),
				borderRadius: BorderRadius.circular(12),
			),
			child: Row(
				children: [
					_periodTab('Tuần', 0),
					_periodTab('Tháng', 1),
				],
			),
		);
	}

	Widget _periodTab(String label, int index) {
		final isSelected = _selectedPeriod == index;
		return Expanded(
			child: GestureDetector(
				onTap: () => setState(() => _selectedPeriod = index),
				child: AnimatedContainer(
					duration: const Duration(milliseconds: 250),
					curve: Curves.easeInOut,
					decoration: BoxDecoration(
						color: isSelected ? const Color(0xFF6C63FF).withValues(alpha: 0.2) : Colors.transparent,
						borderRadius: BorderRadius.circular(10),
						border: isSelected
								? Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3), width: 1)
								: null,
					),
					alignment: Alignment.center,
					child: Text(
						label,
						style: TextStyle(
							color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF6B7280),
							fontSize: 14,
							fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
						),
					),
				),
			),
		);
	}

	// ── Shared components ──
	Widget _sectionCard({required Widget child}) {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: const Color(0xFF12141A),
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: const Color(0xFF1F2330), width: 1),
			),
			child: child,
		);
	}

	Widget _sectionHeader({required String title, required String action}) {
		return Row(
			children: [
				Text(
					title,
					style: const TextStyle(
						color: Color(0xFFE2E5EA),
						fontSize: 17,
						fontWeight: FontWeight.w700,
					),
				),
				const Spacer(),
				GestureDetector(
					onTap: () {},
					child: Row(
						children: [
							Text(
								action,
								style: const TextStyle(
									color: Color(0xFF6C63FF),
									fontSize: 13,
									fontWeight: FontWeight.w600,
								),
							),
							const SizedBox(width: 2),
							const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF6C63FF), size: 12),
						],
					),
				),
			],
		);
	}
}

// ── Data Models ──

class _WalletItem {
	const _WalletItem({
		required this.name,
		required this.balance,
		required this.icon,
		required this.color,
	});

	final String name;
	final String balance;
	final IconData icon;
	final Color color;
}

class _TransactionItem {
	const _TransactionItem({
		required this.title,
		required this.date,
		required this.amount,
		required this.income,
		required this.icon,
		required this.categoryColor,
	});

	final String title;
	final String date;
	final String amount;
	final bool income;
	final IconData icon;
	final Color categoryColor;
}

class _ChartData {
	const _ChartData({
		required this.label,
		required this.income,
		required this.expense,
	});

	final String label;
	final double income;
	final double expense;
}
