import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../workspace/domain/workspace_state.dart';

final expensesProvider = FutureProvider<List<ExpenseItem>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('stock_movements')
      .select(
          'id, product_id, quantity_change, movement_type, notes, created_at, performed_by, products(name, unit_price, cost_price)')
      .eq('workspace_id', wsId)
      .inFilter('movement_type', ['purchase', 'expense'])
      .order('created_at', ascending: false)
      .limit(200);

  return data.map<ExpenseItem>((row) {
    final product = row['products'] as Map<String, dynamic>? ?? {};
    final qty = (row['quantity_change'] as num?)?.toDouble() ?? 0;
    final unitCost = (product['cost_price'] as num?)?.toDouble() ?? 0;
    return ExpenseItem(
      id: row['id'],
      productName: product['name'] as String? ?? row['notes'] ?? 'Expense',
      quantity: qty.abs(),
      unitCost: unitCost,
      total: qty.abs() * unitCost,
      date: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      type: row['movement_type'] as String? ?? 'expense',
    );
  }).toList();
});

final monthlyExpensesTotalProvider = FutureProvider<double>((ref) async {
  final expenses = await ref.watch(expensesProvider.future);
  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  return expenses
      .where((e) => e.date.isAfter(startOfMonth.subtract(const Duration(seconds: 1))))
      .fold<double>(0.0, (sum, e) => sum + e.total);
});

class ExpenseItem {
  final String id;
  final String productName;
  final double quantity;
  final double unitCost;
  final double total;
  final DateTime date;
  final String type;

  const ExpenseItem({
    required this.id,
    required this.productName,
    required this.quantity,
    required this.unitCost,
    required this.total,
    required this.date,
    required this.type,
  });
}
