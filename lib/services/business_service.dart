import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/business.dart';
import '../models/category.dart';
import '../core/constants.dart';
import 'database_service.dart';

class BusinessService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();

  BusinessService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<Business?> getBusiness(String ownerId) async {
    final results = await DatabaseService.query(
      'businesses',
      where: 'owner_id = ?',
      whereArgs: [ownerId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Business.fromMap(results.first);
    }
    return null;
  }

  Future<Business> createBusiness({
    required String ownerId,
    required String name,
    String? address,
    String? phone,
    String? email,
    String? vatNumber,
    String? currency,
    String? currencySymbol,
    double? vatRate,
    String? country,
  }) async {
    final now = DateTime.now();
    final business = Business(
      id: _uuid.v4(),
      ownerId: ownerId,
      name: name,
      address: address,
      phone: phone,
      email: email,
      vatNumber: vatNumber,
      currency: currency ?? 'ZAR',
      currencySymbol: currencySymbol ?? 'R',
      vatRate: vatRate ?? 0.15,
      country: country ?? 'South Africa',
      invoicePrefix: _generateInvoicePrefix(name),
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.insert('businesses', business.toMap());

    await _createDefaultCategories(business.id);

    if (_supabase != null) {
      final client = _supabase;
      try {
        await client.from('businesses').insert(business.toMap());
        await _syncCategoriesToCloud(client, business.id);
      } catch (_) {}
    }

    return business;
  }

  Future<Business> updateBusiness(Business business) async {
    final updated = business.copyWith();
    await DatabaseService.update(
      'businesses',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [business.id],
    );

    final supabase = _supabase;
    if (supabase != null) {
      try {
        await supabase.from('businesses').update(updated.toMap()).eq('id', business.id);
      } catch (_) {}
    }

    return updated;
  }

  Future<List<Category>> getCategories(String businessId, String type) async {
    final results = await DatabaseService.query(
      'categories',
      where: 'business_id = ? AND type = ?',
      whereArgs: [businessId, type],
      orderBy: 'name ASC',
    );
    return results.map((e) => Category.fromMap(e)).toList();
  }

  Future<Category> createCategory({
    required String businessId,
    required String name,
    required String type,
  }) async {
    final category = Category(
      id: _uuid.v4(),
      businessId: businessId,
      name: name,
      type: type,
      createdAt: DateTime.now(),
    );

    await DatabaseService.insert('categories', category.toMap());

    final supabase = _supabase;
    if (supabase != null) {
      try {
        await supabase.from('categories').insert(category.toMap());
      } catch (_) {}
    }

    return category;
  }

  Future<void> deleteCategory(String categoryId) async {
    await DatabaseService.delete('categories', where: 'id = ?', whereArgs: [categoryId]);

    final supabase = _supabase;
    if (supabase != null) {
      try {
        await supabase.from('categories').delete().eq('id', categoryId);
      } catch (_) {}
    }
  }

  Future<void> _createDefaultCategories(String businessId) async {
    for (final name in AppConstants.defaultProductCategories) {
      await createCategory(
        businessId: businessId,
        name: name,
        type: 'product',
      );
    }
    for (final name in AppConstants.defaultExpenseCategories) {
      await createCategory(
        businessId: businessId,
        name: name,
        type: 'expense',
      );
    }
  }

  Future<void> _syncCategoriesToCloud(SupabaseClient client, String businessId) async {
    final categories = await DatabaseService.query(
      'categories',
      where: 'business_id = ?',
      whereArgs: [businessId],
    );
    for (final cat in categories) {
      try {
        await client.from('categories').insert(cat);
      } catch (_) {}
    }
  }

  String _generateInvoicePrefix(String businessName) {
    final words = businessName.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return businessName.length >= 2
        ? businessName.substring(0, 2).toUpperCase()
        : businessName.toUpperCase();
  }
}
