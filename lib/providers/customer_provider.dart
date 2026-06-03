import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _svc;
  List<Customer> _customers = [];
  bool _loading = false;
  String? _error, _search;

  CustomerProvider(this._svc);

  List<Customer> get customers {
    if (_search == null || _search!.isEmpty) return _customers;
    final q = _search!.toLowerCase();
    return _customers.where((c) => c.name.toLowerCase().contains(q) || (c.phone?.toLowerCase().contains(q) ?? false)).toList();
  }
  bool get loading => _loading;
  String? get error => _error;
  int get totalCustomers => _customers.length;

  Future<void> loadCustomers(String bizId) async {
    _loading = true; notifyListeners();
    _customers = await _svc.getCustomers(bizId);
    _loading = false; notifyListeners();
  }

  Future<Customer?> createCustomer({required String businessId, required String name, String? phone, String? email, String? address, String? notes}) async {
    try {
      final c = await _svc.createCustomer(businessId: businessId, name: name, phone: phone, email: email, address: address, notes: notes);
      _customers.add(c); notifyListeners(); return c;
    } catch (e) { _error = e.toString(); notifyListeners(); return null; }
  }

  Future<void> updateCustomer(Customer c) async {
    await _svc.updateCustomer(c);
    final i = _customers.indexWhere((x) => x.id == c.id);
    if (i != -1) _customers[i] = c;
    notifyListeners();
  }

  Future<void> deleteCustomer(String id) async {
    await _svc.deleteCustomer(id);
    _customers.removeWhere((c) => c.id == id); notifyListeners();
  }

  Customer? findById(String id) { try { return _customers.firstWhere((c) => c.id == id); } catch (_) { return null; } }

  void setSearchQuery(String? q) { _search = q; notifyListeners(); }
}
