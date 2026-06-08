import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/fruit_colors.dart';
import '../../data/datasource/SellerRemoteDataSource.dart';

class SellerOrdersScreen extends StatefulWidget {
  final String accessToken;
  const SellerOrdersScreen({super.key, required this.accessToken});

  @override
  State<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends State<SellerOrdersScreen> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = SellerRemoteDataSource().getSellerOrders(widget.accessToken);
  }
  Future<void> _changeStatus(int orderItemId, String newStatus) async {
    bool success = await SellerRemoteDataSource().updateOrderStatus(
        widget.accessToken,
        orderItemId,
        newStatus
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(" Đã cập nhật trạng thái đơn sang: $newStatus"))
      );
      setState(() {
        _ordersFuture = SellerRemoteDataSource().getSellerOrders(widget.accessToken);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen));
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return const Center(child: Text("Không tải được đơn hàng...", style: TextStyle(color: Colors.grey)));
                }

                final orders = snapshot.data!;
                // 🌟 THÊM: RefreshIndicator để Seller làm mới đơn hàng nhanh
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _ordersFuture = SellerRemoteDataSource().getSellerOrders(widget.accessToken);
                    });
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(32),
                    children: [_buildTableContainer(orders)],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: const Row(
        children: [
          Icon(Icons.receipt_long_outlined, color: FruitColors.primaryGreen, size: 24),
          SizedBox(width: 8),
          Text(
            "Quản Lý Đơn Hàng Của Khách (Order Manager)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildTableContainer(List<dynamic> orders) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final List<dynamic> items = order['items'] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Row(
              children: [
                Text("Mã đơn: ${order['orderCode'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _buildStatusBadge(order['orderStatus'] ?? 'PENDING'),
              ],
            ),
            subtitle: Text("Tổng tiền: ${NumberFormat('#,###').format(order['totalPrice'] ?? 0)}đ | ${items.length} mặt hàng"),
            children: [
              const Divider(height: 1),
              ...items.map((item) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    item['imageUrl'] ?? '',
                    width: 50, height: 50, fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(width: 50, height: 50, color: Colors.grey.shade200, child: const Icon(Icons.eco)),
                  ),
                ),
                title: Text(item['productName'] ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("Số lượng: ${item['quantity']} - Giá: ${NumberFormat('#,###').format(item['price'])}đ"),
              )).toList(),

              // Nút hành động của đơn hàng
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: _buildActionButtons(order['orderId'] ?? 0, order['orderStatus'] ?? 'PENDING'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, text;
    String textVi;

    switch (status) {
      case "PENDING":    bg = Colors.orange.shade100; text = Colors.orange.shade900; textVi = "Chờ duyệt"; break;
      case "PROCESSING": bg = Colors.blue.shade100;   text = Colors.blue.shade900;   textVi = "Đang xử lý"; break;
      case "SHIPPING":   bg = Colors.purple.shade100; text = Colors.purple.shade900; textVi = "Đang giao"; break;
      case "DELIVERED":  bg = Colors.green.shade100;  text = Colors.green.shade900;  textVi = "Hoàn thành"; break;
      case "CANCELLED":  bg = Colors.red.shade100;    text = Colors.red.shade900;    textVi = "Đã hủy"; break;
      default:           bg = Colors.grey.shade200;   text = Colors.grey.shade800;   textVi = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(textVi, style: TextStyle(color: text, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  List<Widget> _buildActionButtons(int orderItemId, String status) {
    if (status == "PENDING") {
      return [
        _actionBtn("DUYỆT ĐƠN", Colors.green, () => _changeStatus(orderItemId, "PROCESSING")),
        _actionBtn("HỦY ĐƠN", Colors.red, () => _changeStatus(orderItemId, "CANCELLED")),
      ];
    } else if (status == "PROCESSING") {
      return [
        _actionBtn("GIAO HÀNG", Colors.purple, () => _changeStatus(orderItemId, "SHIPPING")),
      ];
    } else if (status == "SHIPPING") {
      return [
        _actionBtn("HOÀN THÀNH", Colors.teal, () => _changeStatus(orderItemId, "DELIVERED")),
      ];
    }
    return [const Text("Không thể thao tác", style: TextStyle(color: Colors.grey, fontSize: 12))];
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}