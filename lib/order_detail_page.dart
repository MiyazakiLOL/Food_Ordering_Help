import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';
import 'order_repository.dart';
import 'main.dart'; // For formatPriceVnd
import 'app_strings.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderRepository _repo = OrderRepository();
  final _supabase = Supabase.instance.client;
  OrderModel? _initialOrder;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _repo.getOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _initialOrder = order;
        });
      }
    } catch (e) {
      print('${AppStrings.errorPrefix}$e');
    }
  }

  Future<void> _onRefresh() async {
    await _loadOrder();
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _updateStatus(String status) async {
    try {
      final dynamic orderIdInt = int.tryParse(widget.orderId) ?? widget.orderId;

      await _supabase
          .from('Orders')
          .update({'status': status})
          .eq('id', orderIdInt);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppStrings.statusUpdated}$status'), 
          duration: const Duration(seconds: 1),
        ),
      );
      
      _loadOrder();
    } catch (e) {
      print('${AppStrings.updateError}$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.orderTracking),
        backgroundColor: const Color(0xFF0E9F6E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: _initialOrder == null 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _repo.watchOrder(widget.orderId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                        Center(child: Text('${AppStrings.errorPrefix}${snapshot.error}')),
                      ],
                    );
                  }
                  
                  OrderStatus currentStatus = _initialOrder!.status;
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    currentStatus = _parseStatus(snapshot.data!.first['status']);
                  }

                  return _buildMainContent(_initialOrder!, currentStatus);
                },
              ),
            ),
    );
  }

  OrderStatus _parseStatus(String? status) {
    switch (status) {
      case 'buying': return OrderStatus.buying;
      case 'delivering': return OrderStatus.delivering;
      case 'completed': return OrderStatus.completed;
      case 'cancelled': return OrderStatus.cancelled;
      default: return OrderStatus.pending;
    }
  }

  Widget _buildMainContent(OrderModel order, OrderStatus currentStatus) {
    final bool isCancelled = currentStatus == OrderStatus.cancelled;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(25.0),
            child: Column(
              children: [
                _buildStep(AppStrings.statusPending, true),
                _buildLine(currentStatus != OrderStatus.pending && !isCancelled),
                _buildStep(AppStrings.statusBuying, (currentStatus == OrderStatus.buying || currentStatus == OrderStatus.delivering || currentStatus == OrderStatus.completed) && !isCancelled),
                _buildLine((currentStatus == OrderStatus.delivering || currentStatus == OrderStatus.completed) && !isCancelled),
                _buildStep(AppStrings.statusDelivering, (currentStatus == OrderStatus.delivering || currentStatus == OrderStatus.completed) && !isCancelled),
                _buildLine(currentStatus == OrderStatus.completed && !isCancelled),
                _buildStep(AppStrings.statusCompleted, currentStatus == OrderStatus.completed && !isCancelled),

                if (isCancelled)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                    child: const Text(AppStrings.orderCancelled, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                
                if (currentStatus == OrderStatus.completed) _buildInvoice(order),
                
                const SizedBox(height: 30),
                const Divider(),
                _buildOrderDetails(order),
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Text(AppStrings.demoPanelTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _demoButton(AppStrings.demoPending, "pending", Colors.orange),
                  _demoButton(AppStrings.demoBuying, "buying", Colors.blue),
                  _demoButton(AppStrings.demoShip, "delivering", Colors.purple),
                  _demoButton(AppStrings.demoDone, "completed", Colors.green),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildOrderDetails(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(AppStrings.orderDetailsTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...order.items?.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${item.productName} x${item.quantity}"),
              Text(formatPriceVnd(item.unitPrice * item.quantity)),
            ],
          ),
        )) ?? [],
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(AppStrings.totalAmount, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(formatPriceVnd(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0E9F6E))),
          ],
        ),
      ],
    );
  }

  Widget _demoButton(String label, String status, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: () => _updateStatus(status),
      child: Text(label, style: const TextStyle(fontSize: 12)),
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
          const SizedBox(height: 8),
          const Text(AppStrings.deliverySuccess, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(AppStrings.totalPaid),
              Text(formatPriceVnd(order.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String title, bool active) {
    return Row(
      children: [
        Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? Colors.green : Colors.grey[400],
          size: 28,
        ),
        const SizedBox(width: 15),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool active) {
    return Container(
      margin: const EdgeInsets.only(left: 13),
      height: 30,
      width: 2.5,
      color: active ? Colors.green : Colors.grey[300],
    );
  }
}
