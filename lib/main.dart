import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Đã cập nhật Anon Key chuẩn của Đức Anh
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
      title: 'Food Ordering Help',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const OrderTrackingPage(orderId: '1'), // Đang tracking đơn hàng ID = 1
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
        title: const Text("Theo dõi đơn hàng Real-time", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.watchOrder(widget.orderId), // Lắng nghe Real-time từ Supabase
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Lỗi kết nối: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: CircularProgressIndicator()); // Đang đợi dữ liệu
          }

          final order = OrderModel.fromMap(snapshot.data!.first);
          final s = order.status;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                // Các bước trạng thái nhảy tự động
                _buildStep("Đang tìm người mua", s == OrderStatus.searching || s == OrderStatus.bought || s == OrderStatus.shipping || s == OrderStatus.delivered),
                _buildLine(s == OrderStatus.bought || s == OrderStatus.shipping || s == OrderStatus.delivered),
                _buildStep("Đã mua hàng thành công", s == OrderStatus.bought || s == OrderStatus.shipping || s == OrderStatus.delivered),
                _buildLine(s == OrderStatus.shipping || s == OrderStatus.delivered),
                _buildStep("Đang giao hàng tận nơi", s == OrderStatus.shipping || s == OrderStatus.delivered),
                _buildLine(s == OrderStatus.delivered),
                _buildStep("Đã nhận hàng", s == OrderStatus.delivered),
                
                const SizedBox(height: 40),

                // HIỆN HÓA ĐƠN KHI TRẠNG THÁI LÀ DELIVERED
                if (s == OrderStatus.delivered) 
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green, width: 2),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 70),
                        const SizedBox(height: 10),
                        const Text("HOÀN TẤT ĐƠN HÀNG", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                        const Text("Cảm ơn bạn đã tin dùng dịch vụ!", style: TextStyle(fontStyle: FontStyle.italic)),
                        const Divider(height: 30, thickness: 1),
                        _buildInvoiceRow("Mã hóa đơn:", "#ORD-${order.id}"),
                        const SizedBox(height: 10),
                        _buildInvoiceRow("Tổng tiền:", "${order.totalPrice} VNĐ", isPrice: true),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {}, 
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text("Đánh giá 5 sao"),
                        )
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isPrice = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(value, style: TextStyle(
          fontSize: isPrice ? 22 : 16, 
          fontWeight: FontWeight.bold, 
          color: isPrice ? Colors.red : Colors.black
        )),
      ],
    );
  }

  Widget _buildStep(String title, bool active) {
    return Row(
      children: [
        Icon(active ? Icons.check_circle : Icons.radio_button_unchecked, 
             color: active ? Colors.green : Colors.grey[400], size: 35),
        const SizedBox(width: 15),
        Text(title, style: TextStyle(
          fontSize: 17, 
          color: active ? Colors.black : Colors.grey, 
          fontWeight: active ? FontWeight.bold : FontWeight.normal
        )),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 17),
      height: 45,
      width: 3,
      decoration: BoxDecoration(
        color: active ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(10)
      ),
    );
  }
}