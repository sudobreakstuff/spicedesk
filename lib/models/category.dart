class Category {
  final String id;
  final String businessId;
  final String name;
  final String type;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.businessId,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'type': type,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Category copyWith({String? name}) {
    return Category(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      type: type,
      createdAt: createdAt,
    );
  }
}
