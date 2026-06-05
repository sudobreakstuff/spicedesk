import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../sales/data/sales_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../inventory/data/inventory_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesProvider);
    final productsAsync = ref.watch(productsProvider);
    final inventoryAsync = ref.watch(inventoryProvider);
    final currency = NumberFormat.currency(symbol: 'R ', decimalDigits: 2);

    final sales = salesAsync.valueOrNull ?? [];
    final products = productsAsync.valueOrNull ?? [];
    final inventory = inventoryAsync.valueOrNull ?? [];

    final totalRevenue = sales.fold<double>(0, (s, t) => s + t.total);
    final totalCost = inventory.fold<double>(0, (s, i) => s + (i.costPrice * i.quantityOnHand));
    final totalProfit = totalRevenue - totalCost;

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: SpiceColors.textPrimary)),
          const SizedBox(height: 4),
          const Text('All business transactions', style: TextStyle(fontSize: 14, color: SpiceColors.textSecondary)),
          const SizedBox(height: 28),

          // Summary cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SummaryCard(label: 'Total Revenue', value: currency.format(totalRevenue), accent: SpiceColors.accent, icon: Icons.trending_up),
              _SummaryCard(label: 'Cost of Goods', value: currency.format(totalCost), accent: SpiceColors.warning, icon: Icons.shopping_cart),
              _SummaryCard(label: 'Net Profit', value: currency.format(totalProfit), accent: SpiceColors.primary, icon: Icons.account_balance_wallet),
              _SummaryCard(label: 'Products', value: '${products.length}', accent: const Color(0xFF8B5CF6), icon: Icons.inventory_2),
              _SummaryCard(label: 'Transactions', value: '${sales.length}', accent: SpiceColors.danger, icon: Icons.receipt_long),
              _SummaryCard(label: 'Stock Value', value: currency.format(inventory.fold<double>(0, (s, i) => s + (i.unitPrice * i.quantityOnHand))), accent: const Color(0xFF06B6D4), icon: Icons.store),
            ],
          ),

          const SizedBox(height: 36),

          const Text('All Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: SpiceColors.textPrimary)),
          const SizedBox(height: 16),

          if (sales.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SpiceColors.border),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 48, color: SpiceColors.textSecondary),
                    SizedBox(height: 12),
                    Text('No transactions yet', style: TextStyle(color: SpiceColors.textSecondary, fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Sales will appear here after checkout', style: TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border.all(color: SpiceColors.border),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      SizedBox(width: 8),
                      Expanded(flex: 2, child: Text('Txn #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      SizedBox(width: 8),
                      Expanded(flex: 1, child: Text('Method', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      SizedBox(width: 8),
                      Expanded(flex: 2, child: Text('Customer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                      SizedBox(width: 8),
                      Expanded(flex: 1, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SpiceColors.textSecondary))),
                    ],
                  ),
                ),
                // Transaction rows
                ...sales.map((sale) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt.withAlpha(100),
                    border: Border(
                      left: BorderSide(color: SpiceColors.border),
                      right: BorderSide(color: SpiceColors.border),
                      bottom: BorderSide(color: SpiceColors.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          DateFormat('dd/MM/yy HH:mm').format(sale.createdAt),
                          style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          sale.transactionNumber,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SpiceColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: sale.paymentMethod == 'cash' ? SpiceColors.accent.withAlpha(20) : SpiceColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sale.paymentMethod,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sale.paymentMethod == 'cash' ? SpiceColors.accent : SpiceColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          sale.customerName ?? 'Walk-in',
                          style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: Text(
                          currency.format(sale.total),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SpiceColors.accent),
                        ),
                      ),
                    ],
                  ),
                )),
                // Bottom rounded corners
                Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                    border: Border(
                      left: BorderSide(color: SpiceColors.border),
                      right: BorderSide(color: SpiceColors.border),
                      bottom: BorderSide(color: SpiceColors.border),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 48),
          const Center(
            child: Text('Made by Shahid Singh', style: TextStyle(fontSize: 11, color: SpiceColors.textSecondary)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 340,
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: accent.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: SpiceColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
