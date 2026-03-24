enum OrderStatus { pending, buying, delivering, completed }

class OrderModel {
  final String id;
  final OrderStatus status;
  final double totalAmount;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
  });

  // Chuyển dữ liệu từ Supabase (Map) sang Model trong Flutter
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      status: _parseStatus(map['status']),
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'buying': return OrderStatus.buying;
      case 'delivering': return OrderStatus.delivering;
      case 'completed': return OrderStatus.completed;
      default: return OrderStatus.pending;
    }
  }
}
