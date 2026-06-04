import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

final salesProvider = FutureProvider<List<SaleTransaction>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('sales_transactions')
      .select('id, transaction_number, grand_total, payment_method, created_at, customers(name)')
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false)
      .limit(50);

  return data.map<SaleTransaction>((row) {
    final customer = row['customers'] as Map<String, dynamic>?;
    return SaleTransaction(
      id: row['id'],
      transactionNumber: row['transaction_number'] ?? '',
      total: (row['grand_total'] as num?)?.toDouble() ?? 0,
      paymentMethod: row['payment_method'] ?? '',
      customerName: customer?['name'],
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }).toList();
});

final todaySalesProvider = FutureProvider<double>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return 0;

  final today = DateTime.now().toIso8601String().split('T')[0];
  final data = await supabase
      .from('sales_transactions')
      .select('grand_total')
      .eq('workspace_id', wsId)
      .gte('created_at', '$today 00:00:00')
      .lte('created_at', '$today 23:59:59');

  double total = 0;
  for (final row in data) {
    total += (row['grand_total'] as num?)?.toDouble() ?? 0;
  }
  return total;
});

class SaleTransaction {
  final String id;
  final String transactionNumber;
  final double total;
  final String paymentMethod;
  final String? customerName;
  final DateTime createdAt;

  const SaleTransaction({
    required this.id,
    required this.transactionNumber,
    required this.total,
    required this.paymentMethod,
    this.customerName,
    required this.createdAt,
  });
}
