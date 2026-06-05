import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../sales/data/sales_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../customers/data/customers_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../workspace/domain/workspace_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    ref.watch(workspaceStateProvider);
    final userName = (authState.user?.userMetadata?['name'] as String?) ??
        authState.user?.email?.split('@').first ??
        'there';

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';

    final todaySales = ref.watch(todaySalesProvider);
    final weeklySales = ref.watch(weeklySalesProvider);
    final productsAsync = ref.watch(productsProvider);
    final customerCount = ref.watch(customerCountProvider);
    final salesAsync = ref.watch(salesProvider);
    final inventoryAsync = ref.watch(inventoryProvider);

    final format = NumberFormat.currency(symbol: 'R ');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final recentSales = salesAsync.valueOrNull?.take(5).toList() ?? [];
    final lowStockItems = inventoryAsync.valueOrNull
            ?.where((i) => i.quantityOnHand <= i.reorderPoint && i.reorderPoint > 0)
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Text(
            '$greeting, $userName',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: SpiceColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn().slideY(begin: -8),
          const SizedBox(height: 4),
          const Text(
            'Here\'s what\'s happening with your business today.',
            style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary),
          ).animate(delay: 100.ms).fadeIn(),

          const SizedBox(height: 32),

          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _StatCard(
                icon: Icons.trending_up,
                label: 'Today\'s Sales',
                value: todaySales.when(
                  data: (v) => format.format(v),
                  loading: () => null,
                  error: (_, __) => 'R 0.00',
                ),
                accent: SpiceColors.accent,
                isLoading: todaySales.isLoading,
                onTap: () => context.go('/pos'),
              ),
              _StatCard(
                icon: Icons.calendar_view_week_rounded,
                label: 'Weekly Sales',
                value: weeklySales.when(
                  data: (v) => format.format(v.totalSales),
                  loading: () => null,
                  error: (_, __) => 'R 0.00',
                ),
                accent: const Color(0xFF8B5CF6),
                isLoading: weeklySales.isLoading,
                onTap: () => context.go('/reports'),
              ),
              _StatCard(
                icon: Icons.shopping_bag,
                label: 'Total Products',
                value: productsAsync.maybeWhen(
                  data: (v) => v.length.toString(),
                  orElse: () => null,
                ),
                accent: SpiceColors.primary,
                isLoading: productsAsync.isLoading,
                onTap: () => context.go('/inventory'),
              ),
              _StatCard(
                icon: Icons.people,
                label: 'Total Customers',
                value: customerCount.toString(),
                accent: SpiceColors.warning,
                isLoading: false,
                onTap: () => context.go('/customers'),
              ),
            ].animate(interval: 80.ms).fadeIn().slideY(begin: 12),
          ),

          const SizedBox(height: 36),

          const Text('Quick Actions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SpiceColors.textPrimary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.point_of_sale_rounded,
                  label: 'New Sale',
                  subtitle: 'Start a transaction',
                  onTap: () => context.go('/pos'),
                  color: SpiceColors.accent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_box_rounded,
                  label: 'Add Product',
                  subtitle: 'Add to inventory',
                  onTap: () => context.go('/inventory'),
                  color: SpiceColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionCard(
                  icon: Icons.analytics_rounded,
                  label: 'View Reports',
                  subtitle: 'See your analytics',
                  onTap: () => context.go('/reports'),
                  color: SpiceColors.warning,
                ),
              ),
            ]
                .animate(interval: 100.ms, delay: 200.ms)
                .fadeIn()
                .slideY(begin: 12),
          ),

          const SizedBox(height: 36),

          const Text('Recent Transactions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SpiceColors.textPrimary)),
          const SizedBox(height: 16),
          if (salesAsync.isLoading)
            _buildShimmerList(5)
          else if (recentSales.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 32, color: SpiceColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No recent activity',
                      style: TextStyle(color: SpiceColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('Sales and inventory actions will appear here',
                      style: TextStyle(
                          fontSize: 12, color: SpiceColors.textSecondary)),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn()
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Column(
                children: recentSales.asMap().entries.map((entry) {
                  final sale = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: SpiceColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt,
                              size: 18, color: SpiceColors.primary),
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
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textPrimary,
                                ),
                              ),
                              Text(
                                dateFormat.format(sale.createdAt),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: SpiceColors.accent,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate(delay: 400.ms).fadeIn(),

          if (lowStockItems.isNotEmpty) ...[
            const SizedBox(height: 36),
            const Text('Low Stock Alert',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Column(
                children: lowStockItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: SpiceColors.danger.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2_outlined,
                              size: 18, color: SpiceColors.danger),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Reorder point: ${item.reorderPoint.toStringAsFixed(0)} | On hand: ${item.quantityOnHand.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: SpiceColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SpiceColors.danger.withAlpha(20),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantityOnHand.toStringAsFixed(0)} left',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: SpiceColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ).animate(delay: 500.ms).fadeIn().slideY(begin: 8),
          ],

          const SizedBox(height: 48),
          const Center(
            child: Text('Made by Shahid Singh',
                style:
                    TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShimmerList(int count) {
    return Shimmer.fromColors(
      baseColor: SpiceColors.surfaceAlt,
      highlightColor: SpiceColors.border,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SpiceColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SpiceColors.border),
        ),
        child: Column(
          children: List.generate(count, (i) {
            return Padding(
              padding: EdgeInsets.only(top: i > 0 ? 12 : 0),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 12,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 10,
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color accent;
  final VoidCallback? onTap;
  final bool isLoading;

  const _StatCard({
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
                  if (isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.trending_up,
                        size: 14, color: SpiceColors.accent.withAlpha(100)),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                Shimmer.fromColors(
                  baseColor: SpiceColors.surfaceAlt,
                  highlightColor: SpiceColors.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 26,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text(value ?? '-',
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: SpiceColors.textPrimary)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: SpiceColors.textSecondary)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.color,
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
            border: Border.all(color: SpiceColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SpiceColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11,
                            color: SpiceColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward,
                  size: 16, color: SpiceColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
