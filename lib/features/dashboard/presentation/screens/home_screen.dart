import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../sales/data/sales_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../customers/data/customers_provider.dart';
import '../../../inventory/data/inventory_provider.dart';
import '../../../pos/data/quote_service.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../workspace/domain/workspace_state.dart';

class HomeScreen extends ConsumerWidget {
  HomeScreen({super.key});

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
    final inventoryAsync = ref.watch(inventoryProvider);

    final format = NumberFormat.currency(symbol: 'R ');

    final lowStockItems = inventoryAsync.valueOrNull
            ?.where((i) => i.quantityOnHand <= i.reorderPoint && i.reorderPoint > 0)
            .toList() ??
        [];

    final dailySummary = ref.watch(dailySalesProvider);
    final pendingQuotes = ref.watch(pendingQuotesProvider);

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final narrow = constraints.maxWidth < 600;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$greeting, $userName',
                  style: TextStyle(
                    fontSize: narrow ? 22 : 28,
                    fontWeight: FontWeight.w700,
                    color: SpiceColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn().slideY(begin: -8),
                SizedBox(height: 4),
                Text(
                  'Here\'s what\'s happening with your business today.',
                  style: TextStyle(
                    fontSize: narrow ? 12 : 14,
                    color: SpiceColors.textSecondary,
                  ),
                ).animate(delay: 100.ms).fadeIn(),
              ],
            );
          }),

          SizedBox(height: 32),

          LayoutBuilder(builder: (context, constraints) {
            final colCount = constraints.maxWidth < 600
                ? 2
                : constraints.maxWidth <= 900
                    ? 3
                    : 4;
            return GridView.count(
              crossAxisCount: colCount,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
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
                  accent: Color(0xFF8B5CF6),
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
            );
          }),

          SizedBox(height: 36),

          Text('Quick Actions',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SpiceColors.textPrimary)),
          SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final cards = [
              _ActionCard(
                icon: Icons.point_of_sale_rounded,
                label: 'New Sale',
                subtitle: 'Start a transaction',
                onTap: () => context.go('/pos'),
                color: SpiceColors.accent,
              ),
              _ActionCard(
                icon: Icons.add_box_rounded,
                label: 'Add Product',
                subtitle: 'Add to inventory',
                onTap: () => context.go('/inventory'),
                color: SpiceColors.primary,
              ),
              _ActionCard(
                icon: Icons.analytics_rounded,
                label: 'View Reports',
                subtitle: 'See your analytics',
                onTap: () => context.go('/reports'),
                color: SpiceColors.warning,
              ),
            ];
            if (isWide) {
              return Row(
                children: [
                  for (int i = 0; i < cards.length; i++) ...[
                    if (i > 0) SizedBox(width: 16),
                    Expanded(child: cards[i]),
                  ],
                ].animate(interval: 100.ms, delay: 200.ms).fadeIn().slideY(begin: 12),
              );
            }
            return Column(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) SizedBox(height: 12),
                  cards[i],
                ],
              ].animate(interval: 100.ms, delay: 200.ms).fadeIn().slideY(begin: 12),
            );
          }),

          SizedBox(height: 36),

          Text('Daily Summary',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: SpiceColors.textPrimary)),
          SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            final spacer = isWide
                ? SizedBox(width: 16)
                : SizedBox(height: 12);
            final widgets = [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpiceColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SpiceColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.receipt_long_rounded,
                            color: SpiceColors.primary, size: 20),
                      ),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sales',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textSecondary)),
                          SizedBox(height: 2),
                          dailySummary.when(
                            data: (d) => Text(
                              d.transactionCount.toString(),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: SpiceColors.textPrimary),
                            ),
                            loading: () => SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => Text('-',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: SpiceColors.textPrimary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 8),
              spacer,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpiceColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SpiceColors.accent.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.payments_rounded,
                            color: SpiceColors.accent, size: 20),
                      ),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Revenue',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textSecondary)),
                          SizedBox(height: 2),
                          todaySales.when(
                            data: (v) => Text(
                              format.format(v),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: SpiceColors.textPrimary),
                            ),
                            loading: () => SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => Text('-',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: SpiceColors.textPrimary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 350.ms).fadeIn().slideY(begin: 8),
              spacer,
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: SpiceColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: SpiceColors.warning.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.shopping_bag_rounded,
                            color: SpiceColors.warning, size: 20),
                      ),
                      SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Items Sold',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textSecondary)),
                          SizedBox(height: 2),
                          dailySummary.when(
                            data: (d) => Text(
                              d.transactionCount > 0
                                  ? d.transactionCount.toString()
                                  : '0',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: SpiceColors.textPrimary),
                            ),
                            loading: () => SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            error: (_, __) => Text('-',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: SpiceColors.textPrimary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn().slideY(begin: 8),
            ];
            if (isWide) {
              return Row(children: widgets);
            }
            return Column(children: widgets);
          }),

          SizedBox(height: 36),

          Row(children: [
            Text('Pending Orders',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary)),
            Spacer(),
            Material(
              color: SpiceColors.accent.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => context.go('/pos'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: SpiceColors.accent.withAlpha(80)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 14, color: SpiceColors.accent),
                      SizedBox(width: 6),
                      Text('Add Quote',
                          style: TextStyle(
                              fontSize: 13,
                              color: SpiceColors.accent,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          SizedBox(height: 16),
          if (pendingQuotes.isLoading)
            _buildShimmerList(5)
          else if (pendingQuotes.valueOrNull?.isEmpty != false)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 32, color: SpiceColors.textSecondary),
                  SizedBox(height: 12),
                  Text('No pending orders',
                      style: TextStyle(color: SpiceColors.textSecondary)),
                  SizedBox(height: 4),
                  Text('All quotes have been resolved',
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
                children: pendingQuotes.valueOrNull!.asMap().entries.map((entry) {
                  final quote = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: GestureDetector(
                      onTap: () => _showQuoteActionDialog(context, ref, quote),
                      child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: quote.statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.description_rounded,
                              size: 18, color: quote.statusColor),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                quote.quoteNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textPrimary,
                                ),
                              ),
                              Row(
                                children: [
                                  if (quote.customerName != null)
                                    Text(
                                      quote.customerName!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: SpiceColors.textSecondary,
                                      ),
                                    ),
                                  if (quote.customerName != null)
                                    Text(' • ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: SpiceColors.textSecondary,
                                        )),
                                  Text(
                                    quote.displayStatus,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: quote.statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    Text(
                      format.format(quote.total),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
              ),
            ).animate(delay: 400.ms).fadeIn(),

          if (lowStockItems.isNotEmpty) ...[
            SizedBox(height: 36),
            Text('Low Stock Alert',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary)),
            SizedBox(height: 16),
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
                          child: Icon(Icons.inventory_2_outlined,
                              size: 18, color: SpiceColors.danger),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: SpiceColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Reorder point: ${item.reorderPoint.toStringAsFixed(0)} | On hand: ${item.quantityOnHand.toStringAsFixed(0)}',
                                style: TextStyle(
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
                            style: TextStyle(
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

          SizedBox(height: 48),
          Center(
            child: Text('Made by Shahid Singh',
                style:
                    TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
          ),
          SizedBox(height: 32),
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
                  SizedBox(width: 12),
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
                        SizedBox(height: 6),
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

void _showQuoteActionDialog(BuildContext context, WidgetRef ref, PendingQuote quote) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: SpiceColors.surfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: SpiceColors.border),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: quote.statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description_rounded,
                size: 18, color: quote.statusColor),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quote Details',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: SpiceColors.textPrimary)),
                Text(quote.quoteNumber,
                    style: TextStyle(
                        fontSize: 12, color: SpiceColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(ctx),
            icon: Icon(Icons.close,
                size: 20, color: SpiceColors.textSecondary),
          ),
        ],
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _qInfoChip('Status', quote.displayStatus,
                    color: quote.statusColor),
                SizedBox(width: 16),
                _qInfoChip('Total',
                    NumberFormat.currency(symbol: 'R ').format(quote.total)),
                SizedBox(width: 16),
                if (quote.customerName != null)
                  _qInfoChip('Customer', quote.customerName!),
              ],
            ),
            SizedBox(height: 20),
            Text('Actions',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary)),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _qActionButton('Draft', Color(0xFF8B949E),
                    quote.status == 'draft', () async {
                  await _updateQuoteStatus(ctx, ref, quote.id, 'draft');
                }),
                _qActionButton('Sent', Color(0xFF6366F1),
                    quote.status == 'sent', () async {
                  await _updateQuoteStatus(ctx, ref, quote.id, 'sent');
                }),
                _qActionButton('Accepted', Color(0xFF238636),
                    quote.status == 'accepted', () async {
                  await _updateQuoteStatus(ctx, ref, quote.id, 'accepted');
                }),
                _qActionButton('Rejected', Color(0xFFDA3633),
                    quote.status == 'rejected', () async {
                  await _updateQuoteStatus(ctx, ref, quote.id, 'rejected');
                }),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: SpiceColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        backgroundColor: SpiceColors.surfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: SpiceColors.border),
                        ),
                        title: Text('Delete Quote?',
                            style: TextStyle(color: SpiceColors.danger)),
                        content: Text(
                            'This will permanently remove this quote.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: SpiceColors.danger),
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await supabase
                            .from('quote_items')
                            .delete()
                            .eq('quote_id', quote.id);
                        await supabase
                            .from('quotes')
                            .delete()
                            .eq('id', quote.id);
                        ref.invalidate(pendingQuotesProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Quote deleted'),
                              backgroundColor: SpiceColors.accent,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Failed to delete: $e'),
                            backgroundColor: SpiceColors.danger,
                          ));
                        }
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: SpiceColors.danger.withAlpha(80)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('Delete Quote',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: SpiceColors.danger)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _updateQuoteStatus(
    BuildContext ctx, WidgetRef ref, String quoteId, String status) async {
  try {
    await supabase
        .from('quotes')
        .update({'status': status})
        .eq('id', quoteId);
    ref.invalidate(pendingQuotesProvider);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Quote marked as $status'),
        backgroundColor: SpiceColors.accent,
      ));
    }
  } catch (e) {
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('Failed to update: $e'),
        backgroundColor: SpiceColors.danger,
      ));
    }
  }
}

Widget _qInfoChip(String label, String value, {Color? color}) {
  return RichText(
    text: TextSpan(children: [
      TextSpan(
          text: '$label: ',
          style: TextStyle(
              fontSize: 11, color: SpiceColors.textSecondary)),
      TextSpan(
          text: value,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color ?? SpiceColors.textPrimary)),
    ]),
  );
}

Widget _qActionButton(
    String label, Color color, bool isActive, VoidCallback onTap) {
  return Material(
    color: isActive ? color.withAlpha(30) : color.withAlpha(10),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: isActive ? color : color.withAlpha(40)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.check, size: 14, color: SpiceColors.accent),
              ),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? color : color.withAlpha(180))),
          ],
        ),
      ),
    ),
  );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color accent;
  final VoidCallback? onTap;
  final bool isLoading;

  _StatCard({
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
                  Spacer(),
                  if (isLoading)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(Icons.trending_up,
                        size: 14, color: SpiceColors.accent.withAlpha(100)),
                ],
              ),
              SizedBox(height: 16),
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
                      SizedBox(height: 6),
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
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: SpiceColors.textPrimary)),
                SizedBox(height: 2),
                Text(label,
                    style: TextStyle(
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

  _ActionCard({
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
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: SpiceColors.textPrimary)),
                    SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            color: SpiceColors.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward,
                  size: 16, color: SpiceColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
