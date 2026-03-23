import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';

// Giả sử bạn đã khởi tạo Supabase ở hàm main()
// await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');

class OrderTrackingPage extends StatefulWidget {
  final String orderId; // Truyền ID đơn hàng từ màn hình danh sách vào
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final OrderRepository _repo = OrderRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Theo dõi đơn Real-time")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.first;
          final status = data['status'];

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildStep(0, "Đang tìm người", status == 'searching' || status == 'bought' || status == 'shipping' || status == 'delivered'),
                _buildLine(status == 'bought' || status == 'shipping' || status == 'delivered'),
                _buildStep(1, "Đã mua xong", status == 'bought' || status == 'shipping' || status == 'delivered'),
                _buildLine(status == 'shipping' || status == 'delivered'),
                _buildStep(2, "Đang đi giao", status == 'shipping' || status == 'delivered'),
                _buildLine(status == 'delivered'),
                _buildStep(3, "Đã nhận hàng", status == 'delivered'),
                
                const SizedBox(height: 50),
                if (status == 'delivered')
                  Container(
                    padding: const EdgeInsets.all(15),
                    color: Colors.green[50],
                    child: const Text("🎉 Đã giao thành công! Hóa đơn đã được gửi."),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep(int index, String title, bool active) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: active ? Colors.green : Colors.grey[300],
          child: Icon(Icons.check, color: active ? Colors.white : Colors.transparent),
        ),
        const SizedBox(width: 15),
        Text(title, style: TextStyle(fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 20),
      height: 30,
      width: 2,
      color: active ? Colors.green : Colors.grey[300],
    );
  }
}