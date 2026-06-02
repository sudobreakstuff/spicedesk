import 'package:flutter/foundation.dart';
import '../services/business_service.dart';
import '../services/auth_service.dart';
import '../models/business.dart';
import '../models/category.dart' as models;

class BusinessProvider extends ChangeNotifier {
  final BusinessService _businessService;
  final AuthService _authService;

  Business? _business;
  List<models.Category> _productCategories = [];
  List<models.Category> _expenseCategories = [];
  bool _loading = false;
  String? _error;

  BusinessProvider(this._businessService, this._authService);

  Business? get business => _business;
  List<models.Category> get productCategories => _productCategories;
  List<models.Category> get expenseCategories => _expenseCategories;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasBusiness => _business != null;

  Future<void> loadBusiness() async {
    final userId = _authService.userId;
    if (userId == null) return;

    _loading = true;
    notifyListeners();

    try {
      _business = await _businessService.getBusiness(userId);
      if (_business != null) {
        await loadCategories();
      }
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> createBusiness({
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
    final userId = _authService.userId;
    if (userId == null) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _business = await _businessService.createBusiness(
        ownerId: userId,
        name: name,
        address: address,
        phone: phone,
        email: email,
        vatNumber: vatNumber,
        currency: currency,
        currencySymbol: currencySymbol,
        vatRate: vatRate,
        country: country,
      );
      await loadCategories();
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> updateBusiness({
    String? name,
    String? address,
    String? phone,
    String? email,
    String? vatNumber,
    String? currency,
    String? currencySymbol,
    double? vatRate,
    String? country,
    String? invoicePrefix,
    String? receiptFooter,
  }) async {
    if (_business == null) return;

    _loading = true;
    notifyListeners();

    try {
      _business = await _businessService.updateBusiness(
        _business!.copyWith(
          name: name,
          address: address,
          phone: phone,
          email: email,
          vatNumber: vatNumber,
          currency: currency,
          currencySymbol: currencySymbol,
          vatRate: vatRate,
          country: country,
          invoicePrefix: invoicePrefix,
          receiptFooter: receiptFooter,
        ),
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    if (_business == null) return;

    _productCategories = await _businessService.getCategories(_business!.id, 'product');
    _expenseCategories = await _businessService.getCategories(_business!.id, 'expense');
    notifyListeners();
  }

  Future<void> addCategory(String name, String type) async {
    if (_business == null) return;

    try {
      final category = await _businessService.createCategory(
        businessId: _business!.id,
        name: name,
        type: type,
      );
      if (type == 'product') {
        _productCategories.add(category);
      } else {
        _expenseCategories.add(category);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeCategory(String categoryId, String type) async {
    try {
      await _businessService.deleteCategory(categoryId);
      if (type == 'product') {
        _productCategories.removeWhere((c) => c.id == categoryId);
      } else {
        _expenseCategories.removeWhere((c) => c.id == categoryId);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
