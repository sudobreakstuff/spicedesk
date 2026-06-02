class Invoice {
  final String id;
  final String businessId;
  final String? orderId;
  final String? customerId;
  final String invoiceNumber;
  final String? pdfPath;
  final String status;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.businessId,
    this.orderId,
    this.customerId,
    required this.invoiceNumber,
    this.pdfPath,
    this.status = 'Draft',
    required this.createdAt,
  });

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      orderId: map['order_id'] as String?,
      customerId: map['customer_id'] as String?,
      invoiceNumber: map['invoice_number'] as String,
      pdfPath: map['pdf_path'] as String?,
      status: map['status'] as String? ?? 'Draft',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'order_id': orderId,
      'customer_id': customerId,
      'invoice_number': invoiceNumber,
      'pdf_path': pdfPath,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Invoice copyWith({
    String? status,
    String? pdfPath,
  }) {
    return Invoice(
      id: id,
      businessId: businessId,
      orderId: orderId,
      customerId: customerId,
      invoiceNumber: invoiceNumber,
      pdfPath: pdfPath ?? this.pdfPath,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
