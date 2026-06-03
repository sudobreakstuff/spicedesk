import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import 'database_service.dart';
import 'product_service.dart';

class OrderService {
  final SupabaseClient? _supabase;
  final ProductService _productService;
  final _uuid = const Uuid();
  OrderService({SupabaseClient? supabase, ProductService? productService}) : _supabase = supabase, _productService = productService ?? ProductService(supabase: supabase);

  Future<List<OrderModel>> getOrders(String businessId, {String? status, String? orderType, DateTime? fromDate, DateTime? toDate}) async {
    final c = <String>['business_id = ?'];
    final a = <dynamic>[businessId];
    if (status != null) { c.add('status = ?'); a.add(status); }
    if (orderType != null) { c.add('order_type = ?'); a.add(orderType); }
    if (fromDate != null) { c.add('created_at >= ?'); a.add(fromDate.toIso8601String()); }
    if (toDate != null) { c.add('created_at <= ?'); a.add(toDate.toIso8601String()); }
    final w = c.join(' AND ');
    final rows = await DatabaseService.query('SELECT * FROM orders WHERE $w ORDER BY created_at DESC', a);
    return rows.map((r) => OrderModel.fromMap(r)).toList();
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final rows = await DatabaseService.query('SELECT * FROM order_items WHERE order_id = ?', [orderId]);
    return rows.map((r) => OrderItem.fromMap(r)).toList();
  }

  Future<OrderModel> createOrder({required String businessId, String? customerId, required String orderType, required String status, required String paymentMethod, required List<Map<String, dynamic>> items, double discount = 0, double vatRate = 0.15, String? notes}) async {
    final now = DateTime.now();
    final orderId = _uuid.v4();
    double subtotal = 0;
    for (final item in items) { final qty = (item['qty'] as num).toDouble(); final up = (item['unit_price'] as num).toDouble(); subtotal += qty * up; }
    final taxAmount = (subtotal - discount) * vatRate;
    final total = subtotal - discount + taxAmount;
    final order = OrderModel(id: orderId, businessId: businessId, customerId: customerId, orderType: orderType, status: status, subtotal: subtotal, taxAmount: taxAmount, discount: discount, total: total, paymentMethod: paymentMethod, notes: notes, createdAt: now);
    await DatabaseService.insert('orders', order.toMap());
    for (final item in items) {
      final qty = (item['qty'] as num).toDouble();
      final up = (item['unit_price'] as num).toDouble();
      await DatabaseService.insert('order_items', OrderItem(id: _uuid.v4(), orderId: orderId, productId: item['product_id'] as String, productName: item['product_name'] as String, qty: qty, unitPrice: up, total: qty * up).toMap());
      try { final p = await _productService.getProduct(item['product_id'] as String); if (p != null) { await _productService.adjustStock(p.id, p.stockQty - qty); } } catch (_) {}
    }
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('orders').insert(order.toMap()); } catch (_) {} }
    return order;
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await DatabaseService.update('orders', {'status': status}, where: 'id = ?', whereArgs: [id]);
    final supabase = _supabase;
    if (supabase != null) { try { await supabase.from('orders').update({'status': status}).eq('id', id); } catch (_) {} }
  }

  Future<double> getTotalSales(String businessId, {DateTime? fromDate, DateTime? toDate}) async {
    final c = <String>['business_id = ?', "status != 'cancelled'"];
    final a = <dynamic>[businessId];
    if (fromDate != null) { c.add('created_at >= ?'); a.add(fromDate.toIso8601String()); }
    if (toDate != null) { c.add('created_at <= ?'); a.add(toDate.toIso8601String()); }
    final w = c.join(' AND ');
    final rows = await DatabaseService.query('SELECT COALESCE(SUM(total), 0) as total FROM orders WHERE $w', a);
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }
}
