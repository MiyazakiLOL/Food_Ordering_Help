import 'package:supabase_flutter/supabase_flutter.dart';

class OrderRepository {
  final _supabase = Supabase.instance.client;

  // Lắng nghe thay đổi của một đơn hàng cụ thể theo ID
  Stream<List<Map<String, dynamic>>> watchOrder(String orderId) {
    return _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId);
  }
}