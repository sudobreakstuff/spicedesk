class Category {
  final String id;
  final String businessId;
  final String name;
  final String categoryType;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.businessId,
    required this.name,
    required this.categoryType,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      categoryType: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'type': categoryType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
