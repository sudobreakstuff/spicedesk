class OrderModel {
  final String id;
  final String businessId;
  final String? customerId;
  final String orderType;
  final String status;
  final double subtotal;
  final double taxAmount;
  final double discount;
  final double total;
  final String paymentMethod;
  final String? notes;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.businessId,
    this.customerId,
    required this.orderType,
    required this.status,
    required this.subtotal,
    required this.taxAmount,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    this.notes,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      customerId: map['customer_id'] as String?,
      orderType: map['order_type'] as String,
      status: map['status'] as String,
      subtotal: (map['subtotal'] as num).toDouble(),
      taxAmount: (map['tax_amount'] as num).toDouble(),
      discount: (map['discount'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
      paymentMethod: map['payment_method'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'customer_id': customerId,
      'order_type': orderType,
      'status': status,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount': discount,
      'total': total,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final double qty;
  final double unitPrice;
  final double total;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.total,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      productId: map['product_id'] as String,
      productName: map['product_name'] as String,
      qty: (map['qty'] as num).toDouble(),
      unitPrice: (map['unit_price'] as num).toDouble(),
      total: (map['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'product_name': productName,
      'qty': qty,
      'unit_price': unitPrice,
      'total': total,
    };
  }
}
