import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _service;
  List<Customer> _customers = [];
  bool _loading = false;
  String? _error;
  String? _searchQuery;

  CustomerProvider(this._service);

  List<Customer> get customers => _filteredCustomers;
  List<Customer> get allCustomers => _customers;
  bool get loading => _loading;
  String? get error => _error;
  String? get searchQuery => _searchQuery;
  int get totalCustomers => _customers.length;

  List<Customer> get _filteredCustomers {
    if (_searchQuery == null || _searchQuery!.isEmpty) return _customers;
    final query = _searchQuery!.toLowerCase();
    return _customers.where((c) =>
      c.name.toLowerCase().contains(query) ||
      (c.phone?.toLowerCase().contains(query) ?? false)
    ).toList();
  }

  Future<void> loadCustomers(String businessId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _customers = await _service.getCustomers(businessId);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<Customer?> createCustomer({
    required String businessId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final customer = await _service.createCustomer(
        businessId: businessId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );
      _customers.add(customer);
      _loading = false;
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      final updated = await _service.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) _customers[index] = updated;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      await _service.deleteCustomer(customerId);
      _customers.removeWhere((c) => c.id == customerId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Customer? findById(String id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
