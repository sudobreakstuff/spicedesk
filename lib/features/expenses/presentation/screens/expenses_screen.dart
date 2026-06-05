import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../expenses/data/expenses_provider.dart';
import '../../../products/data/products_provider.dart';
import '../../../workspace/domain/workspace_state.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddExpenseDialog() {
    final productsAsync = ref.read(productsProvider);
    final products = (productsAsync.valueOrNull ?? [])
        .where((p) => p.productType == 'raw_material')
        .toList();

    String? selectedProductId;
    final quantityCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    bool isManual = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: const Text('Add Expense',
              style: TextStyle(color: SpiceColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: isManual
                          ? TextField(
                              decoration: const InputDecoration(
                                  labelText: 'Expense Name'),
                              controller: TextEditingController(),
                              onChanged: (_) {},
                            )
                          : products.isEmpty
                              ? const Text('No raw material products',
                                  style: TextStyle(
                                      color: SpiceColors.textSecondary))
                              : DropdownButtonFormField<String>(
                                  initialValue: selectedProductId,
                                  decoration: const InputDecoration(
                                      labelText: 'Product'),
                                  dropdownColor: SpiceColors.surfaceAlt,
                                  style: const TextStyle(
                                      color: SpiceColors.textPrimary,
                                      fontSize: 14),
                                  items: products
                                      .map((p) => DropdownMenuItem(
                                            value: p.id,
                                            child: Text(p.name,
                                                style: const TextStyle(
                                                    fontSize: 13)),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    setDialogState(() {
                                      selectedProductId = v;
                                      if (v != null) {
                                        final prod = products
                                            .firstWhere((p) => p.id == v);
                                        costCtrl.text =
                                            prod.costPrice.toString();
                                      }
                                    });
                                  },
                                ),
                    ),
                    if (!isManual) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_note,
                            color: SpiceColors.textSecondary, size: 20),
                        tooltip: 'Manual entry',
                        onPressed: () => setDialogState(() {
                          isManual = true;
                          selectedProductId = null;
                        }),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Unit Cost (R)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final quantity =
                    double.tryParse(quantityCtrl.text) ?? 0;
                if (quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a valid quantity'),
                        backgroundColor: SpiceColors.warning),
                  );
                  return;
                }

                try {
                  final wsId =
                      ref.read(workspaceStateProvider).selectedId;
                  if (wsId == null) return;

                  if (selectedProductId != null) {
                    await supabase.from('stock_movements').insert({
                      'workspace_id': wsId,
                      'product_id': selectedProductId,
                      'quantity_change': -quantity,
                      'movement_type': 'purchase',
                      'notes': 'Manual expense entry',
                    });

                    await supabase.rpc('update_inventory_quantity', params: {
                      'p_product_id': selectedProductId,
                      'p_workspace_id': wsId,
                      'p_quantity_change': quantity,
                    });
                  } else {
                    await supabase.from('stock_movements').insert({
                      'workspace_id': wsId,
                      'quantity_change': -quantity,
                      'movement_type': 'expense',
                      'notes': 'Manual expense entry',
                    });
                  }

                  ref.invalidate(expensesProvider);
                  ref.invalidate(monthlyExpensesTotalProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                      content: Text('Error adding expense: $e'),
                      backgroundColor: SpiceColors.danger,
                    ));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final monthlyTotalAsync = ref.watch(monthlyExpensesTotalProvider);
    final expenses = expensesAsync.valueOrNull ?? [];
    final monthlyTotal = monthlyTotalAsync.valueOrNull ?? 0;

    final filtered = expenses.where((e) {
      final matchesSearch = _searchQuery.isEmpty ||
          e.productName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesFilter = _filter == 'all' ||
          (_filter == 'purchase' && e.type == 'purchase') ||
          (_filter == 'expense' && e.type == 'expense');
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: SpiceColors.surface,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                const Text('Expenses',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: SpiceColors.textPrimary)),
                const Spacer(),
                SizedBox(
                  width: 280,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddExpenseDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Expense'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SpiceColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: SpiceColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expenses This Month',
                          style: TextStyle(
                              fontSize: 13,
                              color: SpiceColors.textSecondary)),
                      const SizedBox(height: 8),
                      monthlyTotalAsync.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : Text(
                              'R ${monthlyTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: SpiceColors.danger)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == 'all',
                      onSelected: (_) =>
                          setState(() => _filter = 'all'),
                    ),
                    ChoiceChip(
                      label: const Text('Purchases'),
                      selected: _filter == 'purchase',
                      onSelected: (_) =>
                          setState(() => _filter = 'purchase'),
                    ),
                    ChoiceChip(
                      label: const Text('Manual'),
                      selected: _filter == 'expense',
                      onSelected: (_) =>
                          setState(() => _filter = 'expense'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: expensesAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.money_off_rounded,
                                  size: 48,
                                  color: SpiceColors.textSecondary),
                              SizedBox(height: 12),
                              Text('No expenses recorded',
                                  style: TextStyle(
                                      color:
                                          SpiceColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 32),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final e = filtered[index];
                            final isPurchase = e.type == 'purchase';

                            return Container(
                              margin:
                                  const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: SpiceColors.surfaceAlt,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: SpiceColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isPurchase
                                          ? SpiceColors.warning
                                              .withAlpha(30)
                                          : SpiceColors.danger
                                              .withAlpha(30),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isPurchase
                                          ? Icons
                                              .shopping_cart_rounded
                                          : Icons
                                              .receipt_long_rounded,
                                      color: isPurchase
                                          ? SpiceColors.warning
                                          : SpiceColors.danger,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.productName,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight:
                                                    FontWeight.w500,
                                                color: SpiceColors
                                                    .textPrimary),
                                            overflow:
                                                TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Text(
                                          isPurchase
                                              ? 'Raw material purchase'
                                              : 'Manual expense',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: SpiceColors
                                                  .textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 90,
                                    child: Text(
                                      '${e.quantity.toStringAsFixed(0)} ${isPurchase ? "units" : ""}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: SpiceColors
                                              .textPrimary),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      'R ${e.unitCost.toStringAsFixed(2)}/u',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: SpiceColors
                                              .textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      'R ${e.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: SpiceColors.danger),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 100,
                                    child: Text(
                                      '${e.date.day.toString().padLeft(2, '0')}/${e.date.month.toString().padLeft(2, '0')}/${e.date.year}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: SpiceColors
                                              .textSecondary),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (index * 40).ms);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
