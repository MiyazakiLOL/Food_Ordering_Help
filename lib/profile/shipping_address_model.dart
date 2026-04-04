class ShippingAddress {
  final String id;
  final String address;
  final String phone;
  final String note;
  final DateTime? createdAt;

  const ShippingAddress({
    required this.id,
    required this.address,
    required this.phone,
    required this.note,
    this.createdAt,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw);
    }

    return ShippingAddress(
      id: (json['id'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      createdAt: createdAt,
    );
  }
}
