import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  // Lắng nghe thay đổi của một đơn hàng cụ thể (Real-time)
  Stream<List<Map<String, dynamic>>> watchOrder(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId);
  }

  // Hàm này dành cho phía "Người mua hộ" để cập nhật trạng thái
  Future<void> updateStatus(String orderId, String newStatus) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      print("Lỗi cập nhật: $e");
    }
  }
}