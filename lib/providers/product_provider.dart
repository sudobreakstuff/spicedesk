import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as cat_models;
import '../services/product_service.dart';
import '../services/business_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _svc;
  final BusinessService _bizSvc;
  List<Product> _products = [];
  List<cat_models.Category> _categories = [];
  bool _loading = false;
  String? _error;
  String? _catFilter, _search;
  bool _lowStock = false;

  ProductProvider(this._svc, this._bizSvc);

  List<Product> get products {
    var r = _products;
    if (_catFilter != null) r = r.where((p) => p.categoryId == _catFilter).toList();
    if (_search != null && _search!.isNotEmpty) {
      final q = _search!.toLowerCase();
      r = r.where((p) => p.name.toLowerCase().contains(q) || (p.barcode?.toLowerCase().contains(q) ?? false)).toList();
    }
    if (_lowStock) r = r.where((p) => p.isLowStock).toList();
    return r;
  }
  List<cat_models.Category> get categories => _categories;
  bool get loading => _loading;
  int get totalProducts => _products.length;
  int get lowStockCount => _products.where((p) => p.isLowStock).length;

  Future<void> loadProducts(String bizId) async {
    _loading = true; notifyListeners();
    _products = await _svc.getProducts(bizId);
    _categories = await _bizSvc.getCategories(bizId, 'product');
    _loading = false; notifyListeners();
  }

  Future<Product?> createProduct({required String businessId, String? categoryId, required String name, String? description, required double price, double costPrice = 0, int stockQty = 0, int lowStockThreshold = 5, String? barcode}) async {
    try {
      final p = await _svc.createProduct(businessId: businessId, categoryId: categoryId, name: name, description: description, price: price, costPrice: costPrice, stockQty: stockQty.toDouble(), lowStockThreshold: lowStockThreshold.toDouble(), barcode: barcode);
      _products.add(p); notifyListeners(); return p;
    } catch (e) { _error = e.toString(); notifyListeners(); return null; }
  }

  Future<void> updateProduct(Product p) async {
    await _svc.updateProduct(p);
    final i = _products.indexWhere((x) => x.id == p.id);
    if (i != -1) _products[i] = _products[i].copyWith(name: p.name, description: p.description, price: p.price, costPrice: p.costPrice, stockQty: p.stockQty, barcode: p.barcode, categoryId: p.categoryId, lowStockThreshold: p.lowStockThreshold);
    notifyListeners();
  }

  Future<void> adjustStock(String id, int qty) async {
    final i = _products.indexWhere((p) => p.id == id);
    if (i == -1) return;
    final n = _products[i].stockQty + qty;
    if (n < 0) return;
    _products[i] = _products[i].copyWith(stockQty: n);
    notifyListeners();
    await _svc.adjustStock(id, n.toDouble());
  }

  Future<void> deleteProduct(String id) async {
    await _svc.deleteProduct(id);
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<Product?> findByBarcode(String bizId, String code) => _svc.findByBarcode(bizId, code);

  void setCategoryFilter(String? id) { _catFilter = id; notifyListeners(); }
  void setSearchQuery(String? q) { _search = q; notifyListeners(); }
  void toggleLowStockOnly() { _lowStock = !_lowStock; notifyListeners(); }
  void clearFilters() { _catFilter = null; _search = null; _lowStock = false; notifyListeners(); }
}
