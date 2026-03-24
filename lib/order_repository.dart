import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  // Lắng nghe thay đổi của một đơn hàng cụ thể từ bảng 'Orders'
  Stream<List<Map<String, dynamic>>> watchOrder(String orderId) {
    return _supabase
        .from('Orders') // Đảm bảo tên bảng khớp với Supabase (thường là 'Orders' hoặc 'orders')
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
}
