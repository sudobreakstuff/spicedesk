import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../sales/data/sales_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'Daily';
  static const _periods = ['Daily', 'Weekly', 'Monthly'];

  @override
  Widget build(BuildContext context) {
    final todaySalesAsync = ref.watch(todaySalesProvider);
    final dailyAsync = ref.watch(dailySalesProvider);
    final weeklyAsync = ref.watch(weeklySalesProvider);
    final monthlyAsync = ref.watch(monthlySalesProvider);
    final totalTxnsAsync = ref.watch(totalTransactionsProvider);
    final salesAsync = ref.watch(salesProvider);

    final sales = salesAsync.valueOrNull ?? [];
    final format = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);
    final compactFormat = NumberFormat.compactCurrency(symbol: 'R ', decimalDigits: 1);

    final weekTotal = weeklyAsync.valueOrNull?.totalSales ?? 0;
    final monthTotal = monthlyAsync.valueOrNull?.totalSales ?? 0;
    final totalTxns = totalTxnsAsync.valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Reports',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: SpiceColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sales and business analytics',
            style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary),
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _SummaryCard(
                    icon: Icons.today,
                    label: "Today's Sales",
                    accent: SpiceColors.accent,
                    isLoading: todaySalesAsync.isLoading,
                    value: todaySalesAsync.when(
                      data: (v) => format.format(v),
                      loading: () => '...',
                      error: (_, __) => 'R 0.00',
                    ),
                    subtitle:
                        '${dailyAsync.valueOrNull?.transactionCount ?? 0} transactions',
                  ),
                  _SummaryCard(
                    icon: Icons.calendar_view_week,
                    label: 'This Week',
                    accent: SpiceColors.primary,
                    isLoading: weeklyAsync.isLoading,
                    value: weeklyAsync.isLoading ? '...' : format.format(weekTotal),
                    subtitle: weeklyAsync.valueOrNull != null
                        ? 'Best: ${weeklyAsync.valueOrNull!.bestDay}'
                        : '',
                  ),
                  _SummaryCard(
                    icon: Icons.calendar_month,
                    label: 'This Month',
                    accent: SpiceColors.warning,
                    isLoading: monthlyAsync.isLoading,
                    value: monthlyAsync.isLoading
                        ? '...'
                        : format.format(monthTotal),
                    subtitle: monthlyAsync.valueOrNull != null
                        ? 'Avg/day ${compactFormat.format(monthlyAsync.valueOrNull!.dailyAverage)}'
                        : '',
                  ),
                  _SummaryCard(
                    icon: Icons.receipt_long,
                    label: 'Total Transactions',
                    accent: const Color(0xFF8B5CF6),
                    isLoading: totalTxnsAsync.isLoading,
                    value: totalTxnsAsync.isLoading
                        ? '...'
                        : totalTxns.toString(),
                    subtitle: 'All time',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Sales Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary,
                  ),
                ),
              ),
              ..._periods.map(
                (period) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: _selectedPeriod == period,
                    onSelected: (_) =>
                        setState(() => _selectedPeriod = period),
                    backgroundColor: SpiceColors.surfaceAlt,
                    selectedColor: SpiceColors.primary.withAlpha(40),
                    labelStyle: TextStyle(
                      color: _selectedPeriod == period
                          ? SpiceColors.primary
                          : SpiceColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    side: BorderSide(
                      color: _selectedPeriod == period
                          ? SpiceColors.primary
                          : SpiceColors.border,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: SpiceColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SpiceColors.border),
            ),
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildChartTitle(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: _buildChartContent(dailyAsync, weeklyAsync,
                      monthlyAsync, format),
                ),
                const SizedBox(height: 4),
                _buildStatsRow(dailyAsync, weeklyAsync, monthlyAsync,
                    compactFormat),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 36),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SpiceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildTransactionsList(salesAsync, sales, format),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildChartTitle() {
    switch (_selectedPeriod) {
      case 'Daily':
        return const Text(
          'Hourly sales for today',
          style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
        );
      case 'Weekly':
        return const Text(
          'Day-by-day breakdown for this week',
          style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
        );
      case 'Monthly':
        return const Text(
          'Week-by-week breakdown for this month',
          style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChartContent(
    AsyncValue<DailySalesReport> dailyAsync,
    AsyncValue<WeeklySalesReport> weeklyAsync,
    AsyncValue<MonthlySalesReport> monthlyAsync,
    NumberFormat format,
  ) {
    switch (_selectedPeriod) {
      case 'Daily':
        return dailyAsync.when(
          data: (report) {
            final entries = report.hourlyBreakdown.entries
                .map((e) => MapEntry(e.key.toString(), e.value))
                .toList()
              ..sort((a, b) =>
                  int.parse(a.key).compareTo(int.parse(b.key)));
            return _buildBarChart(
              entries: entries,
              getLabel: (i) {
                final hour = int.parse(entries[i].key);
                return hour == 0
                    ? '12am'
                    : hour < 12
                        ? '${hour}am'
                        : hour == 12
                            ? '12pm'
                            : '${hour - 12}pm';
              },
              labelInterval: 3,
              barWidth: 8,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(
              child: Text('Error loading data',
                  style: TextStyle(color: SpiceColors.textSecondary))),
        );
      case 'Weekly':
        return weeklyAsync.when(
          data: (report) {
            const dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final entries = dayOrder
                .map((d) => MapEntry(d, report.dailyBreakdown[d] ?? 0))
                .toList();
            return _buildBarChart(
              entries: entries,
              getLabel: (i) => dayOrder[i],
              labelInterval: 1,
              barWidth: 22,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(
              child: Text('Error loading data',
                  style: TextStyle(color: SpiceColors.textSecondary))),
        );
      case 'Monthly':
        return monthlyAsync.when(
          data: (report) {
            final entries = report.weeklyBreakdown.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));
            return _buildBarChart(
              entries: entries,
              getLabel: (i) => entries[i].key,
              labelInterval: 1,
              barWidth: 32,
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(
              child: Text('Error loading data',
                  style: TextStyle(color: SpiceColors.textSecondary))),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBarChart({
    required List<MapEntry<String, double>> entries,
    required String Function(int) getLabel,
    required int labelInterval,
    required double barWidth,
  }) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('No data for this period',
            style: TextStyle(color: SpiceColors.textSecondary)),
      );
    }

    final allZero = entries.every((e) => e.value == 0);
    final maxY = allZero
        ? 100.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final effectiveMaxY = maxY <= 0 ? 100.0 : maxY * 1.3;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: effectiveMaxY,
        barGroups: List.generate(entries.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entries[i].value,
                color: entries[i].value > 0
                    ? SpiceColors.primary
                    : SpiceColors.primary.withAlpha(60),
                width: barWidth,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                if (i % labelInterval != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    getLabel(i),
                    style: const TextStyle(
                      color: SpiceColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: SpiceColors.border.withAlpha(60),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildStatsRow(
    AsyncValue<DailySalesReport> dailyAsync,
    AsyncValue<WeeklySalesReport> weeklyAsync,
    AsyncValue<MonthlySalesReport> monthlyAsync,
    NumberFormat format,
  ) {
    switch (_selectedPeriod) {
      case 'Daily':
        return dailyAsync.when(
          data: (report) => _StatsRow(children: [
            _StatItem(
                label: 'Transactions',
                value: report.transactionCount.toString()),
            _StatItem(
                label: 'Avg Order',
                value: format.format(report.averageOrderValue)),
            _StatItem(
                label: 'Peak Hour',
                value: report.transactionCount > 0
                    ? '${report.topHour.toString().padLeft(2, '0')}:00'
                    : '—'),
          ]),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      case 'Weekly':
        return weeklyAsync.when(
          data: (report) => _StatsRow(children: [
            _StatItem(
                label: 'Transactions',
                value: report.transactionCount.toString()),
            _StatItem(
                label: 'Avg / Day',
                value: format.format(report.avgPerDay)),
            _StatItem(label: 'Best Day', value: report.bestDay),
          ]),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      case 'Monthly':
        return monthlyAsync.when(
          data: (report) => _StatsRow(children: [
            _StatItem(
                label: 'Transactions',
                value: report.transactionCount.toString()),
            _StatItem(
                label: 'Avg / Week',
                value: format.format(report.avgPerWeek)),
            _StatItem(
                label: 'Daily Avg',
                value: format.format(report.dailyAverage)),
          ]),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTransactionsList(
    AsyncValue<List<SaleTransaction>> salesAsync,
    List<SaleTransaction> sales,
    NumberFormat format,
  ) {
    final recentTxns = sales.take(20).toList();

    if (salesAsync.isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: SpiceColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SpiceColors.border),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (recentTxns.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: SpiceColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SpiceColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long,
                size: 32, color: SpiceColors.textSecondary),
            SizedBox(height: 12),
            Text('No transactions yet',
                style: TextStyle(color: SpiceColors.textSecondary)),
            SizedBox(height: 4),
            Text('Sales will appear here after transactions are completed',
                style: TextStyle(
                    fontSize: 12, color: SpiceColors.textSecondary)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpiceColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: recentTxns.asMap().entries.map((entry) {
          final index = entry.key;
          final sale = entry.value;
          final isEven = index.isEven;
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isEven
                  ? SpiceColors.surfaceAlt
                  : SpiceColors.surface.withAlpha(80),
              border: index < recentTxns.length - 1
                  ? Border(
                      bottom:
                          BorderSide(color: SpiceColors.border.withAlpha(50)),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: SpiceColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt,
                      color: SpiceColors.primary, size: 17),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sale.transactionNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SpiceColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            DateFormat('MMM d, yyyy').format(sale.createdAt),
                            style: const TextStyle(
                                fontSize: 11,
                                color: SpiceColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: SpiceColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('HH:mm').format(sale.createdAt),
                            style: const TextStyle(
                                fontSize: 11,
                                color: SpiceColors.textSecondary),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: SpiceColors.textSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            sale.paymentMethod,
                            style: const TextStyle(
                                fontSize: 11,
                                color: SpiceColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(sale.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.accent,
                      ),
                    ),
                    if (sale.invoiceNumber != null &&
                        sale.invoiceNumber!.isNotEmpty)
                      Text(
                        sale.invoiceNumber!,
                        style: const TextStyle(
                            fontSize: 10,
                            color: SpiceColors.textSecondary),
                      ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color accent;
  final bool isLoading;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.subtitle = '',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SpiceColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              if (!isLoading)
                Icon(Icons.trending_up,
                    size: 14, color: SpiceColors.accent.withAlpha(100))
              else
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: SpiceColors.textPrimary,
              ),
            ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 10, color: SpiceColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final List<Widget> children;

  const _StatsRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: children
            .map((child) => Expanded(child: child))
            .toList(),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: SpiceColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: SpiceColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
