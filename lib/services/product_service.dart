import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import 'database_service.dart';

class ProductService {
  final SupabaseClient? _supabase;
  final _uuid = const Uuid();

  ProductService({SupabaseClient? supabase}) : _supabase = supabase;

  Future<List<Product>> getProducts(String businessId, {String? categoryId, String? search, bool? lowStock}) async {
    var where = 'business_id = ? AND active = 1';
    var whereArgs = [businessId];

    if (categoryId != null) {
      where += ' AND category_id = ?';
      whereArgs.add(categoryId);
    }
    if (search != null && search.isNotEmpty) {
      where += ' AND (name LIKE ? OR barcode LIKE ?)';
      whereArgs.add('%$search%');
      whereArgs.add('%$search%');
    }
    if (lowStock == true) {
      where += ' AND stock_qty <= low_stock_threshold';
    }

    final results = await DatabaseService.query(
      'products',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );

    return results.map((e) => Product.fromMap(e)).toList();
  }

  Future<Product?> getProduct(String productId) async {
    final results = await DatabaseService.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Product.fromMap(results.first);
    }
    return null;
  }

  Future<Product> createProduct({
    required String businessId,
    String? categoryId,
    required String name,
    String? description,
    required double price,
    double costPrice = 0,
    int stockQty = 0,
    String unit = 'each',
    int lowStockThreshold = 5,
    String? barcode,
    String? imagePath,
  }) async {
    final now = DateTime.now();
    final product = Product(
      id: _uuid.v4(),
      businessId: businessId,
      categoryId: categoryId,
      name: name,
      description: description,
      price: price,
      costPrice: costPrice,
      stockQty: stockQty,
      unit: unit,
      lowStockThreshold: lowStockThreshold,
      barcode: barcode,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );

    await DatabaseService.insert('products', product.toMap());
    await _syncToCloud('products', product.id, product.toMap());
    return product;
  }

  Future<Product> updateProduct(Product product) async {
    final updated = product.copyWith();
    final map = updated.toMap();
    await DatabaseService.update('products', map, where: 'id = ?', whereArgs: [product.id]);
    await _syncToCloud('products', product.id, map);
    return updated;
  }

  Future<void> adjustStock(String productId, int quantity) async {
    final product = await getProduct(productId);
    if (product == null) return;

    final newQty = product.stockQty + quantity;
    final updated = product.copyWith(stockQty: newQty < 0 ? 0 : newQty);
    await updateProduct(updated);
  }

  Future<void> deleteProduct(String productId) async {
    final updated = {'active': 0, 'updated_at': DateTime.now().toIso8601String()};
    await DatabaseService.update('products', updated, where: 'id = ?', whereArgs: [productId]);
    await _syncToCloud('products', productId, updated);
  }

  Future<void> _syncToCloud(String table, String id, Map<String, dynamic> data) async {
    final client = _supabase;
    if (client == null) return;
    try {
      await client.from(table).upsert(data);
    } catch (_) {}
  }

  Future<Product?> findByBarcode(String businessId, String barcode) async {
    final results = await DatabaseService.query(
      'products',
      where: 'business_id = ? AND barcode = ? AND active = 1',
      whereArgs: [businessId, barcode],
      limit: 1,
    );
    if (results.isNotEmpty) return Product.fromMap(results.first);
    return null;
  }
}
