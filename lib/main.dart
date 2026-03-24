import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://jibbotejwrsknrixwcpj.supabase.co',
    anonKey: 'sb_publishable_z4QPDgf9Q3nq_kqnWj4bTQ_2i0JORHW',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Ordering App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      // Dùng ID thực tế từ database của bạn
      home: const OrderTrackingPage(orderId: '61f38e07-756d-409e-87b0-e2be5bdd791a'),
    );
  }
}

class OrderTrackingPage extends StatefulWidget {
  final String orderId;
  const OrderTrackingPage({super.key, required this.orderId});

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  final OrderRepository _repo = OrderRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Theo dõi đơn từ Supabase"),
        elevation: 2,
      ),
      body: widget.orderId == 'PASTE_YOUR_UUID_HERE' 
        ? const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Vui lòng thay 'PASTE_YOUR_UUID_HERE' trong file main.dart bằng một ID (UUID) thực tế từ bảng Orders trên Supabase của bạn.", textAlign: TextAlign.center),
          ))
        : StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Lỗi: ${snapshot.error}"),
            ));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text("Đang tìm đơn hàng hoặc ID không tồn tại..."),
                ],
              ),
            );
          }

          // Sử dụng OrderModel để map dữ liệu từ bảng Orders
          final order = OrderModel.fromMap(snapshot.data!.first);
          final status = order.status;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderInfo(order),
                const SizedBox(height: 40),

                _buildStep("Đang tìm người mua hộ", _isReached(status, OrderStatus.pending)),
                _buildLine(_isReached(status, OrderStatus.pending)),

                _buildStep("Đang mua hàng", _isReached(status, OrderStatus.buying)),
                _buildLine(_isReached(status, OrderStatus.delivering)),

                _buildStep("Đang giao hàng", _isReached(status, OrderStatus.delivering)),
                _buildLine(_isReached(status, OrderStatus.completed)),

                _buildStep("Đã nhận hàng thành công", _isReached(status, OrderStatus.completed)),

                const Spacer(),
                if (status == OrderStatus.completed)
                  _buildSuccessMessage(),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isReached(OrderStatus current, OrderStatus step) {
    const sequence = [OrderStatus.pending, OrderStatus.buying, OrderStatus.delivering, OrderStatus.completed];
    return sequence.indexOf(current) >= sequence.indexOf(step);
  }

  Widget _buildOrderInfo(OrderModel order) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mã đơn hàng:"),
                Text(order.id.split('-').first.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Tổng cộng:"),
                Text("${order.totalAmount.toStringAsFixed(0)}đ", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, bool active) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? Colors.green : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(active ? Icons.check : Icons.circle, size: 16, color: active ? Colors.white : Colors.grey[400]),
        ),
        const SizedBox(width: 15),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 14),
      height: 30,
      width: 2,
      color: active ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text("Đơn hàng đã hoàn tất!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
