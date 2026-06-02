class Business {
  final String id;
  final String ownerId;
  final String name;
  final String? logo;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? vatNumber;
  final String currency;
  final String currencySymbol;
  final double vatRate;
  final String country;
  final String? invoicePrefix;
  final String? receiptFooter;
  final bool cloudSyncEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.ownerId,
    required this.name,
    this.logo,
    this.address,
    this.phone,
    this.email,
    this.website,
    this.vatNumber,
    this.currency = 'ZAR',
    this.currencySymbol = 'R',
    this.vatRate = 0.15,
    this.country = 'South Africa',
    this.invoicePrefix,
    this.receiptFooter,
    this.cloudSyncEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromMap(Map<String, dynamic> map) {
    return Business(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      logo: map['logo'] as String?,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      vatNumber: map['vat_number'] as String?,
      currency: map['currency'] as String? ?? 'ZAR',
      currencySymbol: map['currency_symbol'] as String? ?? 'R',
      vatRate: (map['vat_rate'] as num?)?.toDouble() ?? 0.15,
      country: map['country'] as String? ?? 'South Africa',
      invoicePrefix: map['invoice_prefix'] as String?,
      receiptFooter: map['receipt_footer'] as String?,
      cloudSyncEnabled: map['cloud_sync_enabled'] == 1 || map['cloud_sync_enabled'] == true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'logo': logo,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'vat_number': vatNumber,
      'currency': currency,
      'currency_symbol': currencySymbol,
      'vat_rate': vatRate,
      'country': country,
      'invoice_prefix': invoicePrefix,
      'receipt_footer': receiptFooter,
      'cloud_sync_enabled': cloudSyncEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Business copyWith({
    String? name,
    String? logo,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? vatNumber,
    String? currency,
    String? currencySymbol,
    double? vatRate,
    String? country,
    String? invoicePrefix,
    String? receiptFooter,
    bool? cloudSyncEnabled,
  }) {
    return Business(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      vatNumber: vatNumber ?? this.vatNumber,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      vatRate: vatRate ?? this.vatRate,
      country: country ?? this.country,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
