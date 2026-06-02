class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime createdAt;

  Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
  });

  String? get whatsappNumber {
    if (phone == null) return null;
    final digits = phone!.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('0')) return '+27${digits.substring(1)}';
    if (digits.startsWith('+')) return digits;
    if (digits.length == 9) return '+27$digits';
    return '+$digits';
  }

  String get whatsappUri => 'https://wa.me/${whatsappNumber?.replaceAll('+', '')}';

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      businessId: map['business_id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return Customer(
      id: id,
      businessId: businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
