import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  String get _userId {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const AuthException('User is not signed in');
    }
    return user.id;
  }

  // Lắng nghe thay đổi của một đơn hàng cụ thể từ bảng 'Orders'
  Stream<List<Map<String, dynamic>>> watchOrder(String orderId) {
    return _supabase
        .from('Orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId);
  }

  // Hàm cập nhật trạng thái dành cho phía Người mua hộ/Giao hàng
  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('Orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      print("Lỗi khi cập nhật trạng thái: $e");
      rethrow;
    }
  }

  Future<String> createOrder({
    required String shippingAddressId,
    String? voucherId,
    String? note,
    required double shippingFee,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      // 1. Tạo Order
      final orderData = {
        'user_id': _userId,
        'shipping_address_id': int.tryParse(shippingAddressId) ?? shippingAddressId,
        'note': note,
        'shipping_fee': shippingFee.toInt(),
        'total_amount': totalAmount.toInt(),
        'status': 'pending',
      };

      if (voucherId != null) {
        orderData['voucher_id'] = int.tryParse(voucherId) ?? voucherId;
      }

      final orderResponse = await _supabase
          .from('Orders')
          .insert(orderData)
          .select('id')
          .single();

      final orderId = orderResponse['id'].toString();

      // 2. Tạo OrderDetails
      final details = items.map((item) => {
        'order_id': int.tryParse(orderId) ?? orderId,
        'product_id': int.tryParse(item['product_id'].toString()) ?? item['product_id'],
        'quantity': item['quantity'],
        'unit_price': (item['unit_price'] as num).toInt(),
      }).toList();

      await _supabase.from('OrderDetails').insert(details);

      return orderId;
    } catch (e) {
      print("Lỗi khi tạo đơn hàng: $e");
      rethrow;
    }
  }

  Future<List<OrderModel>> getMyOrders() async {
    try {
      final response = await _supabase
          .from('Orders')
          .select('*, OrderDetails(*, Products(name))')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      return (response as List).map((map) => OrderModel.fromMap(map)).toList();
    } catch (e) {
      print("Lỗi khi lấy danh sách đơn hàng: $e");
      rethrow;
    }
  }

  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('Orders')
          .select('*, OrderDetails(*, Products(name))')
          .eq('id', orderId)
          .single();

      return OrderModel.fromMap(response);
    } catch (e) {
      print("Lỗi khi lấy chi tiết đơn hàng: $e");
      rethrow;
    }
  }
}
