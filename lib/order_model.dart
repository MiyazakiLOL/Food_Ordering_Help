enum OrderStatus { pending, buying, delivering, completed, cancelled }

class OrderModel {
  final String id;
  final String userId;
  final String? voucherId;
  final String shippingAddressId;
  final String? note;
  final double shippingFee;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final List<OrderItemModel>? items;

  OrderModel({
    required this.id,
    required this.userId,
    this.voucherId,
    required this.shippingAddressId,
    this.note,
    required this.shippingFee,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      voucherId: map['voucher_id']?.toString(),
      shippingAddressId: map['shipping_address_id'].toString(),
      note: map['note']?.toString(),
      shippingFee: (map['shipping_fee'] ?? 0).toDouble(),
      totalAmount: (map['total_amount'] ?? 0).toDouble(),
      status: _parseStatus(map['status']),
      createdAt: DateTime.parse(map['created_at']),
      items: map['OrderDetails'] != null
          ? (map['OrderDetails'] as List)
              .map((i) => OrderItemModel.fromMap(i))
              .toList()
          : null,
    );
  }

  static OrderStatus _parseStatus(String status) {
    switch (status) {
      case 'buying': return OrderStatus.buying;
      case 'delivering': return OrderStatus.delivering;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case OrderStatus.pending: return 'Chờ xác nhận';
      case OrderStatus.buying: return 'Đang mua';
      case OrderStatus.delivering: return 'Đang giao hàng';
      case OrderStatus.completed: return 'Đã hoàn thành';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }
}

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String? productName; // Thêm để hiển thị

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.productName,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'].toString(),
      orderId: map['order_id'].toString(),
      productId: map['product_id'].toString(),
      quantity: (map['quantity'] ?? 0).toInt(),
      unitPrice: (map['unit_price'] ?? 0).toDouble(),
      productName: map['Products']?['name']?.toString(),
    );
  }
}
