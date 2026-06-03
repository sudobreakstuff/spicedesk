import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import 'database_service.dart';

class CustomerService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();
  CustomerService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<List<Customer>> getCustomers(String businessId, {String? search}) async {
    if (search != null && search.isNotEmpty) {
      final rows = await DatabaseService.query('SELECT * FROM customers WHERE business_id = ? AND (name LIKE ? OR phone LIKE ? OR email LIKE ?) ORDER BY name', [businessId, '%$search%', '%$search%', '%$search%']);
      return rows.map((r) => Customer.fromMap(r)).toList();
    }
    final rows = await DatabaseService.query('SELECT * FROM customers WHERE business_id = ? ORDER BY name', [businessId]);
    return rows.map((r) => Customer.fromMap(r)).toList();
  }

  Future<Customer?> getCustomer(String id) async {
    final rows = await DatabaseService.query('SELECT * FROM customers WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<Customer> createCustomer({required String businessId, required String name, String? phone, String? email, String? address, String? notes}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final customer = Customer(id: id, businessId: businessId, name: name, phone: phone, email: email, address: address, notes: notes, createdAt: now);
    await DatabaseService.insert('customers', customer.toMap());
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('customers').insert(customer.toMap()); } catch (_) {} }
    return customer;
  }

  Future<void> updateCustomer(Customer customer) async {
    await DatabaseService.update('customers', customer.toMap(), where: 'id = ?', whereArgs: [customer.id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('customers').update(customer.toMap()).eq('id', customer.id); } catch (_) {} }
  }

  Future<void> deleteCustomer(String id) async {
    await DatabaseService.delete('customers', where: 'id = ?', whereArgs: [id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('customers').delete().eq('id', id); } catch (_) {} }
  }
}
