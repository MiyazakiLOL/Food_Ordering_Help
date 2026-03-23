enum OrderStatus { searching, bought, shipping, delivered }

class OrderModel {
  final String id;
  final OrderStatus status;
  final double totalPrice;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
  });

  // Chuyển dữ liệu từ Supabase (Map) sang Model trong Flutter
  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'],
      status: _parseStatus(map['status']),
      totalPrice: (map['total_price'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'bought': return OrderStatus.bought;
      case 'shipping': return OrderStatus.shipping;
      case 'delivered': return OrderStatus.delivered;
      default: return OrderStatus.searching;
    }
  }
}