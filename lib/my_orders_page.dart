import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';
import 'order_detail_page.dart';
import 'main.dart'; // For formatPriceVnd

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  final OrderRepository _repo = OrderRepository();
  late Stream<List<Map<String, dynamic>>> _ordersStream;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id;
    _initStream();
  }

  void _initStream() {
    _ordersStream = Supabase.instance.client
        .from('Orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', _userId ?? '')
        .order('created_at', ascending: false);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _initStream();
    });
    // Chờ một chút để tạo cảm giác refresh
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đơn hàng của tôi'),
        backgroundColor: const Color(0xFF0E9F6E),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  Center(child: Text('Lỗi: ${snapshot.error}')),
                ],
              );
            }
            final rows = snapshot.data ?? [];
            if (rows.isEmpty) {
              return ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                  const Center(child: Text('Bạn chưa có đơn hàng nào')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(), // Quan trọng để RefreshIndicator hoạt động
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final orderMap = rows[index];
                final order = OrderModel.fromMap(orderMap);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailPage(orderId: order.id),
                        ),
                      );
                    },
                    title: Text('Đơn hàng #${order.id.substring(0, 8)}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ngày: ${order.createdAt.toLocal().toString().split('.')[0]}'),
                        Text(
                          order.statusText,
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatPriceVnd(order.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0E9F6E),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Colors.orange;
      case OrderStatus.buying: return Colors.blue;
      case OrderStatus.delivering: return Colors.purple;
      case OrderStatus.completed: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }
}
