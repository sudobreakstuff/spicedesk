class AppUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String? businessId;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    this.businessId,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      businessId: map['business_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'business_id': businessId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? businessId,
  }) {
    return AppUser(
      id: id,
      email: email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      businessId: businessId ?? this.businessId,
      createdAt: createdAt,
    );
  }
}
