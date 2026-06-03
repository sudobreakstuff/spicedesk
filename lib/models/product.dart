class Product {
  final String id;
  final String businessId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double costPrice;
  final double stockQty;
  final String? unit;
  final double? lowStockThreshold;
  final String? barcode;
  final String? imagePath;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.businessId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.costPrice,
    this.stockQty = 0,
    this.unit,
    this.lowStockThreshold,
    this.barcode,
    this.imagePath,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num).toDouble(),
      stockQty: (map['stock_qty'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String?,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toDouble(),
      barcode: map['barcode'] as String?,
      imagePath: map['image_path'] as String?,
      active: (map['active'] as int?) != 0,
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
    String? id,
    String? businessId,
    String? categoryId,
    String? name,
    String? description,
    double? price,
    double? costPrice,
    double? stockQty,
    String? unit,
    double? lowStockThreshold,
    String? barcode,
    String? imagePath,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLowStock {
    if (lowStockThreshold == null) return false;
    return stockQty <= lowStockThreshold!;
  }

  bool get isOutOfStock {
    return stockQty <= 0;
  }

  double get profitMargin {
    if (price == 0) return 0;
    return (price - costPrice) / price;
  }
}
