import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('customers')
      .select('id, name, email, phone, address, notes, loyalty_points, created_at')
      .eq('workspace_id', wsId)
      .order('name');

  return data.map<Customer>((row) {
    return Customer(
      id: row['id'],
      name: row['name'] ?? '',
      email: row['email'],
      phone: row['phone'],
      address: row['address'],
      notes: row['notes'],
      loyaltyPoints: row['loyalty_points'] ?? 0,
      createdAt: row['created_at'] != null
          ? DateTime.tryParse(row['created_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }).toList();
});

final customerCountProvider = Provider<int>((ref) {
  final customers = ref.watch(customersProvider).valueOrNull ?? [];
  return customers.length;
});

class Customer {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final int loyaltyPoints;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.notes,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });
}

class CustomerSalesData {
  final double totalSpent;
  final DateTime? lastVisit;
  final int purchaseCount;
  final List<Map<String, dynamic>> recentPurchases;

  const CustomerSalesData({
    this.totalSpent = 0,
    this.lastVisit,
    this.purchaseCount = 0,
    this.recentPurchases = const [],
  });
}

final customerSalesProvider =
    FutureProvider.family<CustomerSalesData, String>((ref, customerId) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return const CustomerSalesData();

  final data = await supabase
      .from('sales_transactions')
      .select('id, transaction_number, grand_total, payment_method, created_at')
      .eq('customer_id', customerId)
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false);

  double totalSpent = 0;
  DateTime? lastVisit;

  for (final txn in data) {
    totalSpent += (txn['grand_total'] as num?)?.toDouble() ?? 0;
    if (lastVisit == null) {
      final created = txn['created_at'];
      if (created != null) {
        lastVisit = DateTime.tryParse(created);
      }
    }
  }

  final recentPurchases = data
      .take(10)
      .map<Map<String, dynamic>>((t) => {
            'id': t['id'],
            'transaction_number': t['transaction_number'] ?? '',
            'grand_total': (t['grand_total'] as num?)?.toDouble() ?? 0,
            'payment_method': t['payment_method'] ?? '',
            'created_at': t['created_at'] ?? '',
          })
      .toList();

  return CustomerSalesData(
    totalSpent: totalSpent,
    lastVisit: lastVisit,
    purchaseCount: data.length,
    recentPurchases: recentPurchases,
  );
});

final allCustomerSalesProvider =
    FutureProvider<Map<String, CustomerSalesData>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return {};

  final data = await supabase
      .from('sales_transactions')
      .select('customer_id, grand_total, created_at')
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false);

  final Map<String, List<Map<String, dynamic>>> grouped = {};
  for (final row in data) {
    final cid = row['customer_id'] as String?;
    if (cid == null) continue;
    grouped.putIfAbsent(cid, () => []).add(row);
  }

  final result = <String, CustomerSalesData>{};
  for (final entry in grouped.entries) {
    double total = 0;
    DateTime? lastVisit;
    for (final txn in entry.value) {
      total += (txn['grand_total'] as num?)?.toDouble() ?? 0;
      if (lastVisit == null) {
        final created = txn['created_at'];
        if (created != null) lastVisit = DateTime.tryParse(created);
      }
    }
    result[entry.key] = CustomerSalesData(
      totalSpent: total,
      lastVisit: lastVisit,
      purchaseCount: entry.value.length,
    );
  }
  return result;
});
