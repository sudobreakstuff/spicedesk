import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service;
  List<OrderModel> _orders = [];
  Map<String, List<OrderItem>> _orderItems = {};
  bool _loading = false;
  String? _error;
  String? _statusFilter;
  String? _typeFilter;
  DateTime? _fromDate;
  DateTime? _toDate;

  OrderProvider(this._service);

  List<OrderModel> get orders => _filteredOrders;
  List<OrderModel> get allOrders => _orders;
  bool get loading => _loading;
  String? get error => _error;
  int get totalOrders => _orders.length;
  double get totalSalesToday => _getSalesForDate(DateTime.now());

  List<OrderModel> get _filteredOrders {
    var result = _orders.toList();
    if (_statusFilter != null) {
      result = result.where((o) => o.status == _statusFilter).toList();
    }
    if (_typeFilter != null) {
      result = result.where((o) => o.orderType == _typeFilter).toList();
    }
    return result;
  }

  double _getSalesForDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    return _orders
        .where((o) => o.createdAt.isAfter(dayStart) && o.createdAt.isBefore(dayEnd))
        .fold(0, (sum, o) => sum + o.total);
  }

  Future<void> loadOrders(String businessId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _service.getOrders(
        businessId,
        status: _statusFilter,
        orderType: _typeFilter,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    if (_orderItems.containsKey(orderId)) return _orderItems[orderId]!;
    final items = await _service.getOrderItems(orderId);
    _orderItems[orderId] = items;
    return items;
  }

  Future<OrderModel?> createOrder({
    required String businessId,
    String? customerId,
    String orderType = 'Walk-in',
    String status = 'Completed',
    required double subtotal,
    required double taxAmount,
    double discount = 0,
    required double total,
    String paymentMethod = 'Cash',
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final order = await _service.createOrder(
        businessId: businessId,
        customerId: customerId,
        orderType: orderType,
        status: status,
        subtotal: subtotal,
        taxAmount: taxAmount,
        discount: discount,
        total: total,
        paymentMethod: paymentMethod,
        notes: notes,
        items: items,
      );
      _orders.insert(0, order);
      _loading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _service.updateOrderStatus(orderId, status);
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = OrderModel(
        id: _orders[index].id,
        businessId: _orders[index].businessId,
        customerId: _orders[index].customerId,
        orderType: _orders[index].orderType,
        status: status,
        subtotal: _orders[index].subtotal,
        taxAmount: _orders[index].taxAmount,
        discount: _orders[index].discount,
        total: _orders[index].total,
        paymentMethod: _orders[index].paymentMethod,
        notes: _orders[index].notes,
        createdAt: _orders[index].createdAt,
      );
      notifyListeners();
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    notifyListeners();
  }

  void setTypeFilter(String? type) {
    _typeFilter = type;
    notifyListeners();
  }

  void clearFilters() {
    _statusFilter = null;
    _typeFilter = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
