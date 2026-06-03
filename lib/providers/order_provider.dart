import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _svc;
  List<OrderModel> _orders = [];
  final Map<String, List<OrderItem>> _items = {};
  bool _loading = false;
  String? _error, _statusFilter, _typeFilter;

  OrderProvider(this._svc);

  List<OrderModel> get orders {
    var r = _orders;
    if (_statusFilter != null) r = r.where((o) => o.status == _statusFilter).toList();
    if (_typeFilter != null) r = r.where((o) => o.orderType == _typeFilter).toList();
    return r;
  }
  bool get loading => _loading;
  int get totalOrders => _orders.length;
  double get totalSalesToday {
    final now = DateTime.now(); final start = DateTime(now.year, now.month, now.day);
    return _orders.where((o) => o.createdAt.isAfter(start)).fold<double>(0, (s, o) => s + o.total);
  }

  Future<void> loadOrders(String bizId) async {
    _loading = true; notifyListeners();
    _orders = await _svc.getOrders(bizId, status: _statusFilter, orderType: _typeFilter);
    _loading = false; notifyListeners();
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    if (_items.containsKey(orderId)) return _items[orderId]!;
    final its = await _svc.getOrderItems(orderId);
    _items[orderId] = its; return its;
  }

  Future<OrderModel?> createOrder({
    required String businessId, String? customerId, String orderType = 'Walk-in',
    String status = 'Completed', double discount = 0, String paymentMethod = 'Cash',
    String? notes, required List<Map<String, dynamic>> items,
  }) async {
    try {
      final o = await _svc.createOrder(
        businessId: businessId, customerId: customerId,
        orderType: orderType, status: status,
        paymentMethod: paymentMethod, discount: discount, notes: notes, items: items,
      );
      _orders.insert(0, o); notifyListeners(); return o;
    } catch (e) { _error = e.toString(); notifyListeners(); return null; }
  }

  Future<void> updateStatus(String id, String status) async {
    await _svc.updateOrderStatus(id, status);
    final i = _orders.indexWhere((o) => o.id == id);
    if (i != -1) _orders[i] = OrderModel(
      id: _orders[i].id, businessId: _orders[i].businessId,
      customerId: _orders[i].customerId, orderType: _orders[i].orderType,
      status: status, subtotal: _orders[i].subtotal, taxAmount: _orders[i].taxAmount,
      discount: _orders[i].discount, total: _orders[i].total,
      paymentMethod: _orders[i].paymentMethod, notes: _orders[i].notes,
      createdAt: _orders[i].createdAt,
    );
    notifyListeners();
  }

  void setStatusFilter(String? s) { _statusFilter = s; notifyListeners(); }
  void setTypeFilter(String? t) { _typeFilter = t; notifyListeners(); }
  void clearFilters() { _statusFilter = null; _typeFilter = null; notifyListeners(); }
}
