import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import 'database_service.dart';

class ProductService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();
  ProductService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<List<Product>> getProducts(String businessId, {String? categoryId, String? search, bool? lowStock}) async {
    final c = <String>[];
    final a = <dynamic>[];
    c.add('business_id = ?');
    a.add(businessId);
    if (categoryId != null) { c.add('category_id = ?'); a.add(categoryId); }
    if (search != null && search.isNotEmpty) { c.add('(name LIKE ? OR barcode LIKE ?)'); a.add('%$search%'); a.add('%$search%'); }
    if (lowStock == true) { c.add('stock_qty > 0 AND low_stock_threshold IS NOT NULL AND stock_qty <= low_stock_threshold'); }
    final w = c.join(' AND ');
    final rows = await DatabaseService.query('SELECT * FROM products WHERE $w ORDER BY name', a);
    return rows.map((r) => Product.fromMap(r)).toList();
  }

  Future<Product?> getProduct(String id) async {
    final rows = await DatabaseService.query('SELECT * FROM products WHERE id = ?', [id]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<Product> createProduct({required String businessId, String? categoryId, required String name, String? description, required double price, required double costPrice, int stockQty = 0, String? unit, double? lowStockThreshold, String? barcode, String? imagePath, bool active = true}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final product = Product(id: id, businessId: businessId, categoryId: categoryId, name: name, description: description, price: price, costPrice: costPrice, stockQty: stockQty, unit: unit, lowStockThreshold: lowStockThreshold, barcode: barcode, imagePath: imagePath, active: active, createdAt: now, updatedAt: now);
    await DatabaseService.insert('products', product.toMap());
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('products').insert(product.toMap()); } catch (_) {} }
    return product;
  }

  Future<void> updateProduct(Product product) async {
    final updated = product.copyWith(updatedAt: DateTime.now());
    await DatabaseService.update('products', updated.toMap(), where: 'id = ?', whereArgs: [updated.id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('products').update(updated.toMap()).eq('id', updated.id); } catch (_) {} }
  }

  Future<Product> adjustStock(String id, double newQty) async {
    final product = await getProduct(id);
    if (product == null) throw Exception('Product not found');
    final updated = product.copyWith(stockQty: newQty.toInt(), updatedAt: DateTime.now());
    await DatabaseService.update('products', updated.toMap(), where: 'id = ?', whereArgs: [id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('products').update(updated.toMap()).eq('id', id); } catch (_) {} }
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    await DatabaseService.delete('products', where: 'id = ?', whereArgs: [id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('products').delete().eq('id', id); } catch (_) {} }
  }

  Future<Product?> findByBarcode(String businessId, String barcode) async {
    final rows = await DatabaseService.query('SELECT * FROM products WHERE business_id = ? AND barcode = ?', [businessId, barcode]);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }
}
