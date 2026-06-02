import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import 'database_service.dart';
import 'product_service.dart';

class OrderService {
  final SupabaseClient? _supabase;
  final ProductService _productService;
  final _uuid = const Uuid();

  OrderService({SupabaseClient? supabase, required ProductService productService})
      : _supabase = supabase,
        _productService = productService;

  Future<List<OrderModel>> getOrders(String businessId, {
    String? status,
    String? orderType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    var where = 'business_id = ?';
    var whereArgs = [businessId];

    if (status != null) {
      where += ' AND status = ?';
      whereArgs.add(status);
    }
    if (orderType != null) {
      where += ' AND order_type = ?';
      whereArgs.add(orderType);
    }
    if (fromDate != null) {
      where += ' AND created_at >= ?';
      whereArgs.add(fromDate.toIso8601String());
    }
    if (toDate != null) {
      where += ' AND created_at <= ?';
      whereArgs.add(toDate.toIso8601String());
    }

    final results = await DatabaseService.query(
      'orders',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return results.map((e) => OrderModel.fromMap(e)).toList();
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final results = await DatabaseService.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    return results.map((e) => OrderItem.fromMap(e)).toList();
  }

  Future<OrderModel> createOrder({
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
    final now = DateTime.now();
    final order = OrderModel(
      id: _uuid.v4(),
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
      createdAt: now,
    );

    await DatabaseService.insert('orders', order.toMap());

    for (final item in items) {
      final orderItem = OrderItem(
        id: _uuid.v4(),
        orderId: order.id,
        productId: item['product_id'] as String,
        productName: item['product_name'] as String,
        qty: item['qty'] as int,
        unitPrice: (item['unit_price'] as num).toDouble(),
        total: (item['total'] as num).toDouble(),
      );
      await DatabaseService.insert('order_items', orderItem.toMap());

      try {
        await _productService.adjustStock(
          item['product_id'] as String,
          -(item['qty'] as int),
        );
      } catch (_) {}
    }

    final client = _supabase;
    if (client != null) {
      try {
        await client.from('orders').insert(order.toMap());
        for (final item in items) {
          final oi = OrderItem(
            id: _uuid.v4(),
            orderId: order.id,
            productId: item['product_id'] as String,
            productName: item['product_name'] as String,
            qty: item['qty'] as int,
            unitPrice: (item['unit_price'] as num).toDouble(),
            total: (item['total'] as num).toDouble(),
          );
          await client.from('order_items').insert(oi.toMap());
        }
      } catch (_) {}
    }

    return order;
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await DatabaseService.update('orders', {'status': status}, where: 'id = ?', whereArgs: [orderId]);
    final client = _supabase;
    if (client != null) {
      try { await client.from('orders').update({'status': status}).eq('id', orderId); } catch (_) {}
    }
  }

  Future<double> getTotalSales(String businessId, {DateTime? fromDate, DateTime? toDate}) async {
    final orders = await getOrders(businessId, fromDate: fromDate, toDate: toDate);
    return orders.fold<double>(0, (sum, o) => sum + o.total);
  }
}
