import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../features/workspace/domain/workspace_state.dart';
import '../../../features/customers/data/customers_provider.dart';

class CustomerSegment {
  final String id;
  final String name;
  final Map<String, dynamic> filters;
  final DateTime createdAt;

  CustomerSegment({
    required this.id,
    required this.name,
    this.filters = const {},
    required this.createdAt,
  });

  factory CustomerSegment.fromJson(Map<String, dynamic> json) {
    return CustomerSegment(
      id: json['id'] as String,
      name: json['name'] as String,
      filters: (json['filters'] as Map<String, dynamic>?) ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

final segmentsProvider =
    FutureProvider<List<CustomerSegment>>((ref) async {
  final wsId = ref.read(workspaceStateProvider).selectedId;
  if (wsId == null) return [];

  final data = await supabase
      .from('customer_segments')
      .select()
      .eq('workspace_id', wsId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => CustomerSegment.fromJson(e)).toList();
});

final createSegmentAction = Provider<Future<void> Function({
  required String name,
  Map<String, dynamic> filters,
})>((ref) {
  return ({
    required String name,
    Map<String, dynamic> filters = const {},
  }) async {
    final wsId = ref.read(workspaceStateProvider).selectedId;
    if (wsId == null) throw Exception('No workspace selected');

    await supabase.from('customer_segments').insert({
      'workspace_id': wsId,
      'name': name,
      'filters': filters,
    });

    ref.invalidate(segmentsProvider);
  };
});

final deleteSegmentAction = Provider<Future<void> Function(String id)>((ref) {
  return (String id) async {
    await supabase.from('customer_segments').delete().eq('id', id);
    ref.invalidate(segmentsProvider);
  };
});

final segmentCustomersProvider =
    FutureProvider.family<List<Customer>, String>((ref, segmentId) async {
  final segment = await ref.read(segmentsProvider.future);
  final seg = segment.where((s) => s.id == segmentId).firstOrNull;
  if (seg == null) return [];

  final allCustomers = await ref.read(customersProvider.future);
  final filters = seg.filters;

  return allCustomers.where((c) {
    if (filters['min_spent'] != null) {
      // spent filtering requires sales data — deferred
    }
    if (filters['has_phone'] == true && (c.phone == null || c.phone!.isEmpty)) {
      return false;
    }
    if (filters['has_email'] == true && (c.email == null || c.email!.isEmpty)) {
      return false;
    }
    return true;
  }).toList();
});
