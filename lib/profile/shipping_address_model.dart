class ShippingAddress {
  final String id;
  final String userId;
  final String fullAddress;
  final String phoneNumber;
  final String note;
  final bool isDefault;
  final DateTime? createdAt;

  const ShippingAddress({
    required this.id,
    required this.userId,
    required this.fullAddress,
    required this.phoneNumber,
    required this.note,
    required this.isDefault,
    this.createdAt,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      fullAddress: (json['full_address'] ?? '').toString(),
      phoneNumber: (json['phone_number'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      isDefault: json['is_default'] ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_address': fullAddress,
      'phone_number': phoneNumber,
      'note': note,
      'is_default': isDefault,
      'user_id': userId,
    };
  }
}
