class VoucherModel {
  final String id;
  final String code;
  final double discountAmount; 
  final DateTime expirationDate;
  final double minOrderValue; 
  final bool isActive;
  final DateTime? createdAt;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.discountAmount,
    required this.expirationDate,
    required this.minOrderValue,
    required this.isActive,
    this.createdAt,
  });

  bool get isValid {
    final now = DateTime.now();
    return isActive && now.isBefore(expirationDate);
  }

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      id: map['id'].toString(),
      code: map['code'].toString().toUpperCase().trim(),
      discountAmount: (map['discount_amount'] ?? 0).toDouble(),
      expirationDate: DateTime.parse(map['expiration_date'].toString()),
      minOrderValue: (map['min_order_value'] ?? 0).toDouble(),
      isActive: map['is_active'] ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : null,
    );
  }

  double calculateDiscount(double subtotal) {
    if (!isValid || subtotal < minOrderValue) return 0;
    return discountAmount;
  }

  String get description {
    return 'Giảm ${_formatPriceVnd(discountAmount)}';
  }

  int get daysLeft {
    final now = DateTime.now();
    return expirationDate.difference(now).inDays;
  }

  bool get isExpiringSoon => daysLeft < 7 && daysLeft >= 0;

  String get expirationText {
    if (daysLeft < 0) return 'Đã hết hạn';
    if (daysLeft == 0) return 'Hôm nay hết';
    if (daysLeft == 1) return 'Ngày mai hết';
    return 'Còn $daysLeft ngày';
  }
}

String _formatPriceVnd(num value) {
  final raw = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    final reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return '${buffer.toString()}đ';
}
