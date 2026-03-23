import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://klygntbdprnavrdswqgj.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtseWdudGJkcHJuYXZyZHN3cWdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQyODU3ODYsImV4cCI6MjA4OTg2MTc4Nn0.9xHRep3DMSDsH2kag_0zB-dTUWpYWv3tZJ5bbsB7P80', 
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const OrderTrackingPage(orderId: '1'),
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
  final _supabase = Supabase.instance.client;

  // Hàm để cập nhật trạng thái trực tiếp từ App
  Future<void> _updateStatus(String status) async {
    await _supabase
        .from('orders')
        .update({'status': status})
        .eq('id', widget.orderId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Demo Real-time - Đức Anh", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.watchOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: CircularProgressIndicator());

          final order = OrderModel.fromMap(snapshot.data!.first);
          final s = order.status;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      _buildStep("Đang tìm người mua", true),
                      _buildLine(s != OrderStatus.searching),
                      _buildStep("Đã mua hàng", s != OrderStatus.searching),
                      _buildLine(s == OrderStatus.shipping || s == OrderStatus.delivered),
                      _buildStep("Đang giao hàng", s == OrderStatus.shipping || s == OrderStatus.delivered),
                      _buildLine(s == OrderStatus.delivered),
                      _buildStep("Đã nhận hàng", s == OrderStatus.delivered),
                      
                      if (s == OrderStatus.delivered) _buildInvoice(order),
                    ],
                  ),
                ),
              ),
              
              // KHU VỰC NÚT BẤM GIẢ LẬP ĐỂ DEMO
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const Text("BẢNG ĐIỀU KHIỂN GIẢ LẬP (Dành cho Demo)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _demoButton("Tìm", "searching", Colors.orange),
                        _demoButton("Mua", "bought", Colors.blue),
                        _demoButton("Ship", "shipping", Colors.purple),
                        _demoButton("Xong", "delivered", Colors.green),
                      ],
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _demoButton(String label, String status, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
      onPressed: () => _updateStatus(status),
      child: Text(label),
    );
  }

  Widget _buildInvoice(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(top: 30),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 50),
          const Text("GIAO HÀNG THÀNH CÔNG", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [const Text("Tổng tiền:"), Text("${order.totalPrice}đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red))],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, bool active) {
    return Row(
      children: [
        Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, color: active ? Colors.green : Colors.grey, size: 30),
        const SizedBox(width: 15),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Container(margin: const EdgeInsets.only(left: 14), height: 35, width: 2, color: active ? Colors.green : Colors.grey[300]);
  }
}