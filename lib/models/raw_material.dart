class RawMaterial {
  final String id;
  final String businessId;
  final String name;
  final double quantity;
  final String unit;
  final double costPerUnit;
  final double reorderLevel;
  final String? supplier;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RawMaterial({
    required this.id,
    required this.businessId,
    required this.name,
    this.quantity = 0,
    this.unit = 'kg',
    this.costPerUnit = 0,
    this.reorderLevel = 0,
    this.supplier,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLow => quantity <= reorderLevel;

  factory RawMaterial.fromMap(Map<String, dynamic> map) {
    return RawMaterial(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'kg',
      costPerUnit: (map['cost_per_unit'] as num?)?.toDouble() ?? 0,
      reorderLevel: (map['reorder_level'] as num?)?.toDouble() ?? 0,
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id, 'business_id': businessId, 'name': name,
      'quantity': quantity, 'unit': unit, 'cost_per_unit': costPerUnit,
      'reorder_level': reorderLevel, 'supplier': supplier, 'notes': notes,
      'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt.toIso8601String(),
    };
  }

  RawMaterial copyWith({
    String? name, double? quantity, String? unit, double? costPerUnit,
    double? reorderLevel, String? supplier, String? notes,
  }) {
    return RawMaterial(
      id: id, businessId: businessId, name: name ?? this.name,
      quantity: quantity ?? this.quantity, unit: unit ?? this.unit,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      supplier: supplier ?? this.supplier, notes: notes ?? this.notes,
      createdAt: createdAt, updatedAt: DateTime.now(),
    );
  }
}
