import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import 'database_service.dart';

class CustomerService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();

  CustomerService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<List<Customer>> getCustomers(String businessId, {String? search}) async {
    var where = 'business_id = ?';
    var whereArgs = [businessId];

    if (search != null && search.isNotEmpty) {
      where += ' AND (name LIKE ? OR phone LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }

    final results = await DatabaseService.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return results.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getCustomer(String customerId) async {
    final results = await DatabaseService.query('customers', where: 'id = ?', whereArgs: [customerId], limit: 1);
    if (results.isNotEmpty) return Customer.fromMap(results.first);
    return null;
  }

  Future<Customer> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final customer = Customer(
      id: _uuid.v4(),
      businessId: businessId,
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await DatabaseService.insert('customers', customer.toMap());
    await _syncToCloud(customer);
    return customer;
  }

  Future<Customer> updateCustomer(Customer customer) async {
    final updated = customer.copyWith();
    await DatabaseService.update('customers', updated.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    await _syncToCloud(updated);
    return updated;
  }

  Future<void> deleteCustomer(String customerId) async {
    await DatabaseService.delete('customers', where: 'id = ?', whereArgs: [customerId]);
    final client = _supabase;
    if (client != null) {
      try { await client.from('customers').delete().eq('id', customerId); } catch (_) {}
    }
  }

  Future<void> _syncToCloud(Customer customer) async {
    final client = _supabase;
    if (client == null) return;
    try { await client.from('customers').upsert(customer.toMap()); } catch (_) {}
  }
}
