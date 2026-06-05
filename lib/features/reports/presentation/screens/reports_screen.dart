import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../sales/data/sales_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../expenses/data/expenses_provider.dart';
import '../../../workspace/domain/workspace_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  final currency = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final wsId = ref.watch(workspaceStateProvider).selectedId;
    final salesAsync = ref.watch(salesProvider);
    final productsAsync = ref.watch(productsProvider);
    final expensesAsync = ref.watch(expensesProvider);

    final sales = salesAsync.valueOrNull ?? [];
    final expenses = expensesAsync.valueOrNull ?? [];

    final totalRevenue = sales.fold<double>(0, (s, t) => s + t.total);
    final totalExpenses = expenses.fold<double>(0, (s, e) => s + e.amount);
    final totalProfit = totalRevenue - totalExpenses;
    final avgOrder = sales.isNotEmpty ? totalRevenue / sales.length : 0.0;

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesProvider);
          ref.invalidate(expensesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(32),
          children: [
            const Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
            const SizedBox(height: 4),
            Text(wsId == null ? 'Select a workspace to view reports' : 'Business performance overview',
                style: const TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
            const SizedBox(height: 28),

            if (wsId == null)
              Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                child: const Center(child: Text('No workspace selected', style: TextStyle(color: SpiceColors.textSecondary))),
              )
            else ...[
              // Summary cards
              Wrap(spacing: 16, runSpacing: 16, children: [
                _Card(label: 'Total Revenue', value: currency.format(totalRevenue), accent: SpiceColors.accent, icon: Icons.trending_up),
                _Card(label: 'Total Expenses', value: currency.format(totalExpenses), accent: SpiceColors.danger, icon: Icons.money_off),
                _Card(label: 'Net Profit', value: currency.format(totalProfit), accent: totalProfit >= 0 ? SpiceColors.accent : SpiceColors.danger, icon: Icons.account_balance),
                _Card(label: 'Transactions', value: '${sales.length}', accent: SpiceColors.primary, icon: Icons.receipt_long),
                _Card(label: 'Avg Order', value: currency.format(avgOrder), accent: const Color(0xFF8B5CF6), icon: Icons.analytics),
                _Card(label: 'Expenses Count', value: '${expenses.length}', accent: SpiceColors.warning, icon: Icons.receipt),
              ]),

              const SizedBox(height: 36),

              // Most & Least Sold
              if (sales.isNotEmpty) ...[
                const Text('Product Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getProductSales(),
                  builder: (_, snap) {
                    final data = snap.data ?? [];
                    if (data.isEmpty) return const SizedBox.shrink();
                    data.sort((a, b) => ((b['total_sold'] as num?)?.toDouble() ?? 0).compareTo((a['total_sold'] as num?)?.toDouble() ?? 0));
                    final top = data.take(3).toList();
                    final bottom = data.reversed.take(3).toList();
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Most Sold', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.accent)),
                              const SizedBox(height: 12),
                              ...top.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Expanded(child: Text(p['product_name'] ?? '', style: const TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                                  Text('${((p['total_sold'] as num?)?.toDouble() ?? 0).toInt()} sold',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent)),
                                ]),
                              )),
                              if (top.isEmpty) const Text('No data', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Least Sold', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SpiceColors.warning)),
                              const SizedBox(height: 12),
                              ...bottom.map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(children: [
                                  Expanded(child: Text(p['product_name'] ?? '', style: const TextStyle(fontSize: 13, color: SpiceColors.textPrimary))),
                                  Text('${((p['total_sold'] as num?)?.toDouble() ?? 0).toInt()} sold',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.warning)),
                                ]),
                              )),
                              if (bottom.isEmpty) const Text('No data', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                            ]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 36),
              ],

              // Transaction table
              const Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
              const SizedBox(height: 4),
              Text('${sales.length} transactions | ${currency.format(totalRevenue)} total',
                  style: const TextStyle(fontSize: 13, color: SpiceColors.textSecondary)),
              const SizedBox(height: 16),

              if (sales.isEmpty)
                Container(
                  padding: const EdgeInsets.all(48),
                  decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: const Center(child: Text('No transactions yet', style: TextStyle(color: SpiceColors.textSecondary))),
                )
              else
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: const BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                      child: const Row(children: [
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Txn #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Method', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                        Expanded(flex: 1, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      ]),
                    ),
                    ...sales.asMap().entries.map((e) {
                      final s = e.value;
                      final isEven = e.key % 2 == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isEven ? SpiceColors.surfaceAlt.withAlpha(60) : Colors.transparent,
                          border: const Border(top: BorderSide(color: SpiceColors.border)),
                        ),
                        child: Row(children: [
                          Expanded(flex: 2, child: Text(DateFormat('dd/MM/yy HH:mm').format(s.createdAt), style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                          Expanded(flex: 2, child: Text(s.transactionNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary))),
                          Expanded(flex: 1, child: Text(s.paymentMethod.toString().substring(0, 4), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: s.paymentMethod == 'cash' ? SpiceColors.accent : SpiceColors.primary))),
                          Expanded(flex: 2, child: Text(s.customerName ?? 'Walk-in', style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary))),
                          Expanded(flex: 1, child: Text(currency.format(s.total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SpiceColors.accent))),
                        ]),
                      );
                    }),
                  ]),
                ),
            ],

            const SizedBox(height: 48),
            const Center(child: Text('Made by Shahid Singh', style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary))),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getProductSales() async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) return [];
    try {
      final data = await supabase
          .from('sale_items')
          .select('product_name, quantity')
          .eq('workspace_id', wsId);
      final Map<String, double> totals = {};
      for (final row in data) {
        final name = row['product_name'] as String? ?? '';
        final qty = (row['quantity'] as num?)?.toDouble() ?? 0;
        totals[name] = (totals[name] ?? 0) + qty;
      }
      return totals.entries.map((e) => {'product_name': e.key, 'total_sold': e.value}).toList();
    } catch (_) {
      return [];
    }
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final Color accent;
  final IconData icon;
  const _Card({required this.label, required this.value, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: SpiceColors.surfaceAlt, borderRadius: BorderRadius.circular(12), border: Border.all(color: SpiceColors.border)),
        child: Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: accent.withAlpha(25), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: accent, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
          ])),
        ]),
      ),
    );
  }
}
