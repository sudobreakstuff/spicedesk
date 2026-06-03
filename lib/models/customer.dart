class Customer {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.createdAt,
  });

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
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String? get whatsappNumber {
    if (phone == null || phone!.isEmpty) return null;
    String num = phone!.replaceAll(RegExp(r'[^0-9+]'), '');
    if (num.startsWith('+')) {
      return num;
    }
    if (num.startsWith('0')) {
      num = num.substring(1);
    }
    if (num.length == 9) {
      return '+27$num';
    }
    return '+$num';
  }

  Uri? get whatsappUri {
    final num = whatsappNumber;
    if (num == null) return null;
    final clean = num.replaceAll('+', '');
    return Uri.parse('https://wa.me/$clean');
  }
}
