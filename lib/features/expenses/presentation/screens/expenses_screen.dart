import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../products/data/products_provider.dart';
import '../../../workspace/domain/workspace_state.dart';
import '../../data/expenses_provider.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  void _showAddExpenseDialog() {
    final descriptionCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String category = 'general';
    DateTime selectedDate = DateTime.now();
    bool isRawMaterial = false;
    String? selectedProductId;
    final quantityCtrl = TextEditingController();

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
                TextField(
                  controller: descriptionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (R)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  dropdownColor: SpiceColors.surfaceAlt,
                  style: const TextStyle(
                      color: SpiceColors.textPrimary, fontSize: 14),
                  items: [
                    'general',
                    'rent',
                    'utilities',
                    'supplies',
                    'marketing',
                    'other'
                  ].map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                            c[0].toUpperCase() + c.substring(1)),
                      )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => category = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setDialogState(() => selectedDate = d);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: SpiceColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(
                          color: SpiceColors.textPrimary, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Raw Material Purchase',
                      style: TextStyle(
                          fontSize: 14,
                          color: SpiceColors.textPrimary)),
                  value: isRawMaterial,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: SpiceColors.warning,
                  onChanged: (v) {
                    setDialogState(() {
                      isRawMaterial = v;
                      if (!v) {
                        selectedProductId = null;
                        quantityCtrl.clear();
                      }
                    });
                  },
                ),
                if (isRawMaterial) ...[
                  const SizedBox(height: 8),
                  _RawMaterialPicker(
                    onChanged: (productId, costPrice) {
                      selectedProductId = productId;
                      if (costPrice > 0) {
                        amountCtrl.text = costPrice.toString();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Quantity'),
                  ),
                ],
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
                final description = descriptionCtrl.text.trim();
                final amount =
                    double.tryParse(amountCtrl.text) ?? 0;
                if (description.isEmpty && amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Please enter a description and amount'),
                        backgroundColor: SpiceColors.warning),
                  );
                  return;
                }

                try {
                  final wsId =
                      ref.read(workspaceStateProvider).selectedId;
                  if (wsId == null) return;

                  await supabase.from('expenses').insert({
                    'workspace_id': wsId,
                    'description': description,
                    'category': category,
                    'amount': amount,
                    'expense_date': selectedDate.toIso8601String(),
                    'notes':
                        notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                  });

                  if (isRawMaterial && selectedProductId != null) {
                    final qty =
                        double.tryParse(quantityCtrl.text) ?? 0;
                    if (qty > 0 && selectedProductId != null) {
                      final pid = selectedProductId!;
                      final existing = await supabase
                          .from('inventory')
                          .select('id, quantity_on_hand')
                          .eq('workspace_id', wsId)
                          .eq('product_id', pid)
                          .maybeSingle();

                      if (existing != null) {
                        await supabase
                            .from('inventory')
                            .update({
                              'quantity_on_hand': (existing['quantity_on_hand'] as num).toDouble() + qty,
                            })
                            .eq('id', existing['id']);
                      } else {
                        await supabase.from('inventory').insert({
                          'workspace_id': wsId,
                          'product_id': pid,
                          'quantity_on_hand': qty,
                          'reorder_point': 10,
                        });
                      }
                    }
                  }

                  ref.invalidate(expensesProvider);
                  ref.invalidate(monthlyExpensesProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Error adding expense: $e'),
                        backgroundColor: SpiceColors.danger,
                      ),
                    );
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

  void _showEditExpenseDialog(ExpenseItem expense) {
    final descriptionCtrl =
        TextEditingController(text: expense.description);
    final amountCtrl =
        TextEditingController(text: expense.amount.toString());
    final notesCtrl = TextEditingController(text: expense.notes ?? '');
    String category = expense.category;
    DateTime selectedDate = expense.date;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: SpiceColors.surfaceAlt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: SpiceColors.border),
          ),
          title: const Text('Edit Expense',
              style: TextStyle(color: SpiceColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Amount (R)'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration:
                      const InputDecoration(labelText: 'Category'),
                  dropdownColor: SpiceColors.surfaceAlt,
                  style: const TextStyle(
                      color: SpiceColors.textPrimary, fontSize: 14),
                  items: [
                    'general',
                    'rent',
                    'utilities',
                    'supplies',
                    'marketing',
                    'other'
                  ].map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(
                            c[0].toUpperCase() + c.substring(1)),
                      )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => category = v);
                    }
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setDialogState(() => selectedDate = d);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: SpiceColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('dd/MM/yyyy').format(selectedDate),
                      style: const TextStyle(
                          color: SpiceColors.textPrimary,
                          fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Notes'),
                  maxLines: 2,
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
                final description = descriptionCtrl.text.trim();
                final amount =
                    double.tryParse(amountCtrl.text) ?? 0;

                try {
                  final wsId =
                      ref.read(workspaceStateProvider).selectedId;
                  if (wsId == null) return;

                  await supabase
                      .from('expenses')
                      .update({
                        'description': description,
                        'category': category,
                        'amount': amount,
                        'expense_date':
                            selectedDate.toIso8601String(),
                        'notes': notesCtrl.text.trim().isEmpty
                            ? null
                            : notesCtrl.text.trim(),
                      })
                      .eq('id', expense.id);

                  ref.invalidate(expensesProvider);
                  ref.invalidate(monthlyExpensesProvider);

                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content:
                            Text('Error updating expense: $e'),
                        backgroundColor: SpiceColors.danger,
                      ),
                    );
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

  void _deleteExpense(ExpenseItem expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SpiceColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SpiceColors.border),
        ),
        title: const Text('Delete Expense'),
        content: Text(
          'Are you sure you want to delete "${expense.description}"?',
          style: const TextStyle(color: SpiceColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase
                    .from('expenses')
                    .delete()
                    .eq('id', expense.id);

                ref.invalidate(expensesProvider);
                ref.invalidate(monthlyExpensesProvider);

                if (ctx.mounted) Navigator.pop(ctx);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text('Error deleting expense: $e'),
                    backgroundColor: SpiceColors.danger,
                  ));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SpiceColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showExpenseActions(ExpenseItem expense) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SpiceColors.surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: SpiceColors.border),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SpiceColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  expense.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: SpiceColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit, color: SpiceColors.primary),
                title: const Text('Edit'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditExpenseDialog(expense);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: SpiceColors.danger),
                title: const Text('Delete'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteExpense(expense);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'rent':
        return const Color(0xFFF59E0B);
      case 'utilities':
        return const Color(0xFF3B82F6);
      case 'supplies':
        return const Color(0xFF8B5CF6);
      case 'marketing':
        return const Color(0xFFEC4899);
      case 'other':
        return SpiceColors.textSecondary;
      default:
        return SpiceColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final monthlyTotalAsync = ref.watch(monthlyExpensesProvider);
    final expenses = expensesAsync.valueOrNull ?? [];
    final monthlyTotal = monthlyTotalAsync.valueOrNull ?? 0;

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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: SpiceColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SpiceColors.border),
              ),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Total',
                          style: TextStyle(
                              fontSize: 13,
                              color: SpiceColors.textSecondary)),
                      SizedBox(height: 4),
                    ],
                  ),
                  const SizedBox(width: 12),
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
                              color: SpiceColors.danger),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: expensesAsync.isLoading
                  ? const Center(
                      child: CircularProgressIndicator())
                  : expenses.isEmpty
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
                          padding:
                              const EdgeInsets.only(bottom: 32),
                          itemCount: expenses.length,
                          itemBuilder: (context, index) {
                            final e = expenses[index];
                            final catColor =
                                _categoryColor(e.category);

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: GestureDetector(
                                onLongPress: () =>
                                    _showExpenseActions(e),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 14),
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
                                          color: catColor
                                              .withAlpha(30),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                        ),
                                        child: Icon(
                                          Icons.receipt_long_rounded,
                                          color: catColor,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment
                                                  .start,
                                          children: [
                                            Text(e.description,
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight
                                                            .w500,
                                                    color: SpiceColors
                                                        .textPrimary),
                                                overflow:
                                                    TextOverflow
                                                        .ellipsis),
                                            const SizedBox(
                                                height: 2),
                                            if ((e.notes ?? '')
                                                .isNotEmpty)
                                              Text(e.notes!,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: SpiceColors
                                                          .textSecondary)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: catColor
                                              .withAlpha(25),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  6),
                                        ),
                                        child: Text(
                                          e.category.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: catColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          'R ${e.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color:
                                                  SpiceColors.danger),
                                          textAlign:
                                              TextAlign.right,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          DateFormat('dd/MM/yy')
                                              .format(e.date),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: SpiceColors
                                                  .textSecondary),
                                          textAlign:
                                              TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RawMaterialPicker extends ConsumerWidget {
  final void Function(String productId, double costPrice) onChanged;

  const _RawMaterialPicker({required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);
    final products = (productsAsync.valueOrNull ?? [])
        .where((p) => p.productType == 'raw_material')
        .toList();

    if (productsAsync.isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (products.isEmpty) {
      return const Text('No raw material products available',
          style: TextStyle(
              color: SpiceColors.textSecondary, fontSize: 13));
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Product'),
      dropdownColor: SpiceColors.surfaceAlt,
      style: const TextStyle(
          color: SpiceColors.textPrimary, fontSize: 14),
      items: products
          .map((p) => DropdownMenuItem(
                value: p.id,
                child:
                    Text(p.name, style: const TextStyle(fontSize: 13)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          final prod = products.firstWhere((p) => p.id == v);
          onChanged(v, prod.costPrice);
        }
      },
    );
  }
}
