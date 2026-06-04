import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_theme.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 4),
        Text('Sales and business analytics',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 20),

        // Summary cards
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Today',
                amount: 'R 0.00',
                trend: '+0%',
                positive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'This Week',
                amount: 'R 0.00',
                trend: '+0%',
                positive: true,
              ),
            ),
          ],
        ).animate().fadeIn().slideY(begin: 0.1),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'This Month',
                amount: 'R 0.00',
                trend: '+0%',
                positive: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Avg. Order',
                amount: 'R 0.00',
                trend: '0 orders',
                positive: true,
              ),
            ),
          ],
        ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),

        const SizedBox(height: 28),

        // Sales chart
        Text('Sales Overview',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: SpiceColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpiceColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last 7 Days',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 100,
                    barGroups: List.generate(7, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: [10, 25, 15, 40, 30, 20, 5][i].toDouble(),
                            color: SpiceColors.primary,
                            width: 20,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                days[value.toInt()],
                                style: const TextStyle(
                                    color: SpiceColors.textSecondary,
                                    fontSize: 12),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: SpiceColors.border.withAlpha(80),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ).animate(delay: 200.ms).fadeIn(),

        const SizedBox(height: 24),

        // Top products
        Text('Top Products', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: SpiceColors.surfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: SpiceColors.border),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _topProductRow('Espresso', 45, 1125.00, context),
              const Divider(height: 20),
              _topProductRow('Cappuccino', 38, 1140.00, context),
              const Divider(height: 20),
              _topProductRow('Latte', 32, 1024.00, context),
              const Divider(height: 20),
              _topProductRow('Croissant', 28, 616.00, context),
            ],
          ),
        ).animate(delay: 400.ms).fadeIn(),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _topProductRow(
      String name, int qty, double amount, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(name, style: Theme.of(context).textTheme.bodyLarge),
        ),
        Text('$qty sold',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: 16),
        Text(
          'R ${amount.toStringAsFixed(2)}',
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String amount;
  final String trend;
  final bool positive;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.trend,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SpiceColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SpiceColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Text(amount,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(trend,
              style: TextStyle(
                color:
                    positive ? SpiceColors.accent : SpiceColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
