import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';

final customersProvider = FutureProvider<List<Customer>>((ref) async {
  final wsId = ref.watch(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('customers')
      .select('id, name, email, phone, loyalty_points, created_at')
      .eq('workspace_id', wsId)
      .order('name');

  return data.map<Customer>((row) {
    return Customer(
      id: row['id'],
      name: row['name'] ?? '',
      email: row['email'],
      phone: row['phone'],
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
  final int loyaltyPoints;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.loyaltyPoints = 0,
    required this.createdAt,
  });
}
