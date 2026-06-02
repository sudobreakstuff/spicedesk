import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/category.dart' as models;
import '../services/product_service.dart';
import '../services/business_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService;
  final BusinessService _businessService;

  List<Product> _products = [];
  List<models.Category> _categories = [];
  bool _loading = false;
  String? _error;
  String? _categoryFilter;
  String? _searchQuery;
  bool _showLowStockOnly = false;

  ProductProvider(this._productService, this._businessService);

  List<Product> get products => _filteredProducts;
  List<Product> get allProducts => _products;
  List<models.Category> get categories => _categories;
  bool get loading => _loading;
  String? get error => _error;
  String? get categoryFilter => _categoryFilter;
  String? get searchQuery => _searchQuery;
  bool get showLowStockOnly => _showLowStockOnly;

  List<Product> get _filteredProducts {
    var result = _products.toList();
    if (_categoryFilter != null) {
      result = result.where((p) => p.categoryId == _categoryFilter).toList();
    }
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      result = result.where((p) =>
        p.name.toLowerCase().contains(query) ||
        (p.barcode?.toLowerCase().contains(query) ?? false)
      ).toList();
    }
    if (_showLowStockOnly) {
      result = result.where((p) => p.isLowStock).toList();
    }
    return result;
  }

  int get totalProducts => _products.length;
  int get lowStockCount => _products.where((p) => p.isLowStock).length;
  int get outOfStockCount => _products.where((p) => p.isOutOfStock).length;

  Future<void> loadProducts(String businessId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getProducts(businessId);
      _categories = await _businessService.getCategories(businessId, 'product');
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<Product?> createProduct({
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
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final product = await _productService.createProduct(
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
      );
      _products.add(product);
      _loading = false;
      notifyListeners();
      return product;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateProduct(Product product) async {
    _loading = true;
    notifyListeners();

    try {
      final updated = await _productService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) _products[index] = updated;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> adjustStock(String productId, int quantity) async {
    try {
      await _productService.adjustStock(productId, quantity);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updated = _products[index].copyWith(
          stockQty: _products[index].stockQty + quantity,
        );
        _products[index] = updated;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _productService.deleteProduct(productId);
      _products.removeWhere((p) => p.id == productId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Product?> findByBarcode(String businessId, String barcode) async {
    try {
      return await _productService.findByBarcode(businessId, barcode);
    } catch (_) {
      return null;
    }
  }

  void setCategoryFilter(String? categoryId) {
    _categoryFilter = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleLowStockOnly() {
    _showLowStockOnly = !_showLowStockOnly;
    notifyListeners();
  }

  void clearFilters() {
    _categoryFilter = null;
    _searchQuery = null;
    _showLowStockOnly = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
