import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../products/data/products_provider.dart';
import '../../../sales/data/sales_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todaySales = ref.watch(todaySalesProvider);
    final salesAsync = ref.watch(salesProvider);
    final productsAsync = ref.watch(productsProvider);

    final sales = salesAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];
    final format = NumberFormat.currency(symbol: 'R ');

    final totalSales =
        sales.fold<double>(0, (sum, s) => sum + s.total);

    final chartData =
        sales.take(12).toList().reversed.toList();
    final maxY = chartData.isEmpty
        ? 100.0
        : chartData.map((s) => s.total).reduce((a, b) => a > b ? a : b) *
            1.2;

    final recentTxns = sales.take(10).toList();

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
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
            style: TextStyle(
                fontSize: 14, color: SpiceColors.textSecondary),
          ),
          const SizedBox(height: 32),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _SummaryCard(
                icon: Icons.today,
                label: "Today's Sales",
                value: todaySales.when(
                  data: (v) => format.format(v),
                  loading: () => '...',
                  error: (_, __) => 'R 0.00',
                ),
                accent: SpiceColors.accent,
                isLoading: todaySales.isLoading,
                onTap: () => context.go('/pos'),
              ),
              _SummaryCard(
                icon: Icons.attach_money,
                label: 'Total Sales',
                value: salesAsync.isLoading
                    ? '...'
                    : format.format(totalSales),
                accent: SpiceColors.primary,
                isLoading: salesAsync.isLoading,
                onTap: () => context.go('/pos'),
              ),
              _SummaryCard(
                icon: Icons.inventory_2,
                label: 'Products',
                value: productsAsync.isLoading
                    ? '...'
                    : products.length.toString(),
                accent: SpiceColors.warning,
                isLoading: productsAsync.isLoading,
                onTap: () => context.go('/inventory'),
              ),
              _SummaryCard(
                icon: Icons.receipt_long,
                label: 'Transactions',
                value: salesAsync.isLoading
                    ? '...'
                    : sales.length.toString(),
                accent: const Color(0xFF8B5CF6),
                isLoading: salesAsync.isLoading,
                onTap: () {},
              ),
            ].animate(interval: 80.ms).fadeIn().slideY(begin: 12),
          ),
          const SizedBox(height: 36),

          const Text(
            'Sales Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: SpiceColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: SpiceColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SpiceColors.border),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Last 12 Transactions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: SpiceColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: salesAsync.isLoading
                      ? const Center(
                          child: CircularProgressIndicator())
                      : chartData.isEmpty
                          ? const Center(
                              child: Text(
                                'No sales data',
                                style: TextStyle(
                                    color:
                                        SpiceColors.textSecondary),
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment:
                                    BarChartAlignment.spaceAround,
                                maxY: maxY,
                                barGroups:
                                    List.generate(chartData.length,
                                        (i) {
                                  return BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: chartData[i].total,
                                        color: SpiceColors.primary,
                                        width: 16,
                                        borderRadius:
                                            const BorderRadius
                                                .vertical(
                                          top: Radius.circular(4),
                                        ),
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
                                      getTitlesWidget:
                                          (value, meta) {
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(
                                                  top: 8),
                                          child: Text(
                                            '${value.toInt() + 1}',
                                            style: const TextStyle(
                                              color: SpiceColors
                                                  .textSecondary,
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine:
                                      (value) => FlLine(
                                    color: SpiceColors.border
                                        .withAlpha(80),
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData:
                                    FlBorderData(show: false),
                              ),
                            ),
                ),
              ],
            ),
          ).animate(delay: 200.ms).fadeIn(),
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
          if (salesAsync.isLoading)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ).animate(delay: 400.ms).fadeIn()
          else if (recentTxns.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long,
                      size: 32,
                      color: SpiceColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No transactions yet',
                      style: TextStyle(
                          color: SpiceColors.textSecondary)),
                  SizedBox(height: 4),
                  Text(
                      'Sales will appear here after transactions are completed',
                      style: TextStyle(
                          fontSize: 12,
                          color: SpiceColors.textSecondary)),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn()
          else
            ...recentTxns.asMap().entries.map((entry) {
              final index = entry.key;
              final sale = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: SpiceColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SpiceColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: SpiceColors.primary.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt,
                          color: SpiceColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.transactionNumber,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: SpiceColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${sale.paymentMethod}  \u2022  ${DateFormat('MMM d, yyyy').format(sale.createdAt)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: SpiceColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      format.format(sale.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.accent,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 40).ms);
            }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;
  final VoidCallback? onTap;
  final bool isLoading;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SpiceColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SpiceColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
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
                        size: 14,
                        color: SpiceColors.accent.withAlpha(100))
                  else
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.textPrimary,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: SpiceColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
