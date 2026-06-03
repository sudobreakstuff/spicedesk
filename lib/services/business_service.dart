import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business.dart';
import '../models/category.dart';
import 'database_service.dart';

class BusinessService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();
  BusinessService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<Business?> getBusiness(String ownerId) async {
    final rows = await DatabaseService.query('SELECT * FROM businesses WHERE owner_id = ?', [ownerId]);
    if (rows.isEmpty) return null;
    return Business.fromMap(rows.first);
  }

  Future<Business> createBusiness({required String ownerId, required String name, String? address, String? phone, String? email, String? vatNumber, String currency = 'ZAR', String currencySymbol = 'R', double vatRate = 0.15, String country = 'South Africa'}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final business = Business(id: id, ownerId: ownerId, name: name, address: address, phone: phone, email: email, vatNumber: vatNumber, currency: currency, currencySymbol: currencySymbol, vatRate: vatRate, country: country, createdAt: now, updatedAt: now);
    await DatabaseService.insert('businesses', business.toMap());
    await _createDefaultCategories(id, now);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('businesses').insert(business.toMap()); } catch (_) {} }
    return business;
  }

  Future<void> updateBusiness(Business business) async {
    final updated = business.copyWith(updatedAt: DateTime.now());
    await DatabaseService.update('businesses', updated.toMap(), where: 'id = ?', whereArgs: [updated.id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('businesses').update(updated.toMap()).eq('id', updated.id); } catch (_) {} }
  }

  Future<List<Category>> getCategories(String businessId, String type) async {
    final rows = await DatabaseService.query('SELECT * FROM categories WHERE business_id = ? AND type = ? ORDER BY name', [businessId, type]);
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  Future<Category> createCategory({required String businessId, required String name, required String type}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final category = Category(id: id, businessId: businessId, name: name, categoryType: type, createdAt: now);
    await DatabaseService.insert('categories', category.toMap());
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('categories').insert(category.toMap()); } catch (_) {} }
    return category;
  }

  Future<void> deleteCategory(String id) async {
    await DatabaseService.delete('categories', where: 'id = ?', whereArgs: [id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('categories').delete().eq('id', id); } catch (_) {} }
  }

  Future<void> _createDefaultCategories(String businessId, DateTime now) async {
    final pc = ['Samosas','Bhajias','Pakoras','Sweets','Beverages','Snacks','Meals','Other'];
    final ec = ['Ingredients','Packaging','Rent','Electricity','Water','Transport','Salaries','Marketing','Maintenance','Other'];
    for (final n in pc) { await DatabaseService.insert('categories', Category(id: _uuid.v4(), businessId: businessId, name: n, categoryType: 'product', createdAt: now).toMap()); }
    for (final n in ec) { await DatabaseService.insert('categories', Category(id: _uuid.v4(), businessId: businessId, name: n, categoryType: 'expense', createdAt: now).toMap()); }
  }
}
