import 'package:flutter/foundation.dart';
import '../services/business_service.dart';
import '../services/auth_service.dart';
import '../models/business.dart';
import '../models/category.dart' as cat_models;

class BusinessProvider extends ChangeNotifier {
  final BusinessService _svc;
  final AuthService _auth;
  Business? _business;
  List<cat_models.Category> _pCats = [], _eCats = [];
  bool _loading = false;
  String? _error;

  BusinessProvider(this._svc, this._auth);

  Business? get business => _business;
  List<cat_models.Category> get productCategories => _pCats;
  List<cat_models.Category> get expenseCategories => _eCats;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasBusiness => _business != null;

  Future<void> loadBusiness() async {
    final uid = _auth.userId; if (uid == null) return;
    _loading = true; notifyListeners();
    _business = await _svc.getBusiness(uid);
    if (_business != null) { _pCats = await _svc.getCategories(_business!.id, 'product'); _eCats = await _svc.getCategories(_business!.id, 'expense'); }
    _loading = false; notifyListeners();
  }

  Future<void> createBusiness({required String name, String? address, String? phone, String? email, String? vatNumber, double? vatRate}) async {
    final uid = _auth.userId; if (uid == null) return;
    _loading = true; _error = null; notifyListeners();
    try {
      _business = await _svc.createBusiness(ownerId: uid, name: name, address: address, phone: phone, email: email, vatNumber: vatNumber, vatRate: vatRate ?? 0.15);
      _pCats = await _svc.getCategories(_business!.id, 'product');
      _eCats = await _svc.getCategories(_business!.id, 'expense');
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<void> updateBusiness({String? name, String? address, String? phone, String? email, String? vatNumber, double? vatRate, String? receiptFooter}) async {
    if (_business == null) return;
    await _svc.updateBusiness(_business!.copyWith(name: name, address: address, phone: phone, email: email, vatNumber: vatNumber, vatRate: vatRate, receiptFooter: receiptFooter));
    _business = _business!.copyWith(name: name, address: address, phone: phone, email: email, vatNumber: vatNumber, vatRate: vatRate, receiptFooter: receiptFooter);
    notifyListeners();
  }

  void clearError() { _error = null; notifyListeners(); }
}
