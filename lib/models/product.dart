class Product {
  final String id;
  final String businessId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double costPrice;
  final int stockQty;
  final String unit;
  final int lowStockThreshold;
  final String? barcode;
  final String? imagePath;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.costPrice = 0,
    this.stockQty = 0,
    this.unit = 'each',
    this.lowStockThreshold = 5,
    this.barcode,
    this.imagePath,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock => stockQty <= lowStockThreshold;
  bool get isOutOfStock => stockQty <= 0;
  double get profitMargin => price > 0 ? ((price - costPrice) / price * 100) : 0;

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0,
      stockQty: map['stock_qty'] as int? ?? 0,
      unit: map['unit'] as String? ?? 'each',
      lowStockThreshold: map['low_stock_threshold'] as int? ?? 5,
      barcode: map['barcode'] as String?,
      imagePath: map['image_path'] as String?,
      active: map['active'] == 1 || map['active'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'category_id': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'cost_price': costPrice,
      'stock_qty': stockQty,
      'unit': unit,
      'low_stock_threshold': lowStockThreshold,
      'barcode': barcode,
      'image_path': imagePath,
      'active': active ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product copyWith({
    String? categoryId,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    int? stockQty,
    String? unit,
    int? lowStockThreshold,
    String? barcode,
    String? imagePath,
    bool? active,
  }) {
    return Product(
      id: id,
      businessId: businessId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stockQty: stockQty ?? this.stockQty,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      barcode: barcode ?? this.barcode,
      imagePath: imagePath ?? this.imagePath,
      active: active ?? this.active,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
