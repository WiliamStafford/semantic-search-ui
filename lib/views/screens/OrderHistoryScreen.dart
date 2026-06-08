import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/utils/format_utils.dart';
import '../theme/fruit_colors.dart';
import '../../data/datasource/user_remote_data_source.dart';
import 'CreateReturnScreen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String accessToken;

  const OrderHistoryScreen({super.key, required this.accessToken});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<dynamic>> _ordersFuture;
  int? _userId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserAndOrders();
  }

  Future<void> _fetchUserAndOrders() async {
    try {
      final userProfile = await UserRemoteDataSource().getUserProfile(widget.accessToken);
      if (mounted) {
        setState(() {
          _userId = userProfile.id;
          _isLoadingUser = false;
          _ordersFuture = _fetchOrders(userProfile.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<List<dynamic>> _fetchOrders(int userId) async {
    final response = await http.get(
      Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/orders/user/$userId'),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'ngrok-skip-browser-warning': 'any',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không thể tải lịch sử đơn hàng');
    }
  }

  Future<void> _handleRefresh() async {
    if (_userId != null) {
      setState(() {
        _ordersFuture = _fetchOrders(_userId!);
      });
    }
  }

  void _showReviewDialog(int orderItemId, int productId, dynamic firstItem) {
    int selectedStars = 5;
    bool isSending = false;
    bool isSuccess = false;
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(isSuccess ? "Thông báo" : "Đánh giá sản phẩm"),
          content: isSuccess
              ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text("Cảm ơn bạn đã gửi đánh giá!", textAlign: TextAlign.center),
            ],
          )
              : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Chọn số sao:"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < selectedStars ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                  onPressed: isSending ? null : () => setDialogState(() => selectedStars = i + 1),
                )),
              ),
              TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: "Nhập nhận xét (tùy chọn)...", border: OutlineInputBorder()),
                  maxLines: 2
              ),
            ],
          ),
          actions: [
            if (isSuccess)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleRefresh();
                },
                child: const Text("ĐÓNG"),
              )
            else ...[
              TextButton(onPressed: isSending ? null : () => Navigator.pop(context), child: const Text("HỦY")),
              ElevatedButton(
                onPressed: isSending ? null : () async {
                  setDialogState(() => isSending = true);
                  try {
                    final res = await http.post(
                      Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/reviews/add'),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization': 'Bearer ${widget.accessToken}'
                      },
                      body: jsonEncode({
                        'orderItemId': orderItemId,
                        'productId': productId == 0 ? orderItemId : productId,
                        'rating': selectedStars,
                        'comment': controller.text.trim(),
                      }),
                    );

                    if (res.statusCode == 200 && mounted) {
                      setDialogState(() => isSuccess = true);
                    } else {
                      String errorMsg = "Lỗi hệ thống";
                      try {
                        final body = jsonDecode(utf8.decode(res.bodyBytes));
                        errorMsg = body['message'] ?? "Lỗi: ${res.statusCode}";
                      } catch (_) {}

                      _showSnackBar(errorMsg, Colors.red);
                      setDialogState(() => isSending = false);
                    }
                  } catch (e) {
                    _showSnackBar("Không thể kết nối máy chủ", Colors.red);
                    setDialogState(() => isSending = false);
                  }
                },
                child: isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("GỬI"),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: FruitColors.accentGreen)),
      );
    }

    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _userId == null
                ? _buildErrorState("Không thể xác định danh tính người dùng.")
                : FutureBuilder<List<dynamic>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen));
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  color: FruitColors.primaryGreen,
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(32),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(orders[index]),
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
          Text("Đơn hàng của tôi",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
          Spacer(),
          Icon(Icons.history, color: FruitColors.accentGreen),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    String status = order['orderStatus'] ?? 'PENDING';
    final List<dynamic> items = (order['items'] as List?) ?? [];
    final rawPrice = order['totalPrice'] ?? order['totalAmount'] ?? 0;
    final formattedPrice = rawPrice is num ? NumberFormat('#,###').format(rawPrice) : rawPrice.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- PHẦN HEADER ĐƠN HÀNG ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mã đơn: #${order['id'] ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              _buildStatusChip(status),
            ],
          ),
          const Divider(height: 24),

          ...items.map((item) {
            bool isDelivered = status == 'DELIVERED';
            bool hasReviewed = item['reviewed'] == true || item['isReviewed'] == true;
            bool hasComplaint = item['hasComplaint'] == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['imageUrl'] ?? '',
                          width: 50, height: 50, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50, height: 50,
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image, size: 24, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['productName'] ?? 'Sản phẩm', style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text("Số lượng: ${item['quantity']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text(FormatUtils.vnCurrency.format(item['price'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),

                  if (isDelivered)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Nút Khiếu nại
                          TextButton.icon(
                            icon: Icon(hasComplaint ? Icons.check_circle : Icons.assignment_return, size: 16),
                            label: Text(hasComplaint ? "Đã khiếu nại" : "Khiếu nại"),
                            style: TextButton.styleFrom(foregroundColor: hasComplaint ? Colors.grey : Colors.orange),
                            onPressed: hasComplaint ? null : () => _navigateToReturnForm(item),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            icon: Icon(hasReviewed ? Icons.star : Icons.star_border, size: 16),
                            label: Text(hasReviewed ? "Đã đánh giá" : "Đánh giá"),
                            style: TextButton.styleFrom(foregroundColor: hasReviewed ? Colors.grey : Colors.blue),
                            onPressed: hasReviewed ? null : () {
                              final int itemId = (item['id'] != null) ? (item['id'] as num).toInt() : 0;
                              final int prodId = (item['productId'] != null) ? (item['productId'] as num).toInt() : 0;

                              if (itemId == 0) {
                                _showSnackBar("Lỗi: Dữ liệu mặt hàng không hợp lệ (Thiếu OrderItemID)", Colors.red);
                              } else {
                                _showReviewDialog(
                                    itemId,
                                    prodId != 0 ? prodId : itemId, //
                                    item
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),

          const Divider(height: 24),

          // --- PHẦN FOOTER (TỔNG TIỀN VÀ ACTION) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Tổng: ${FormatUtils.vnCurrency.format(order['totalPrice'])}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );

  }

  Widget _buildStatusChip(String status) {
    Color baseColor;
    switch (status) {
      case 'PENDING':
        baseColor = Colors.orange;
        break;
      case 'PAID':
      case 'DELIVERED':
        baseColor = Colors.green;
        break;
      case 'SHIPPING':
        baseColor = Colors.blue;
        break;
      case 'CANCELLED':
        baseColor = Colors.red;
        break;
      default:
        baseColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: baseColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: baseColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: FruitColors.softGreen.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Bạn chưa có đơn hàng nào.", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text("Lỗi: $error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  void _navigateToReturnForm(dynamic item) {
    if (_userId == null) {
      _showSnackBar("Đang tải dữ liệu người dùng...", Colors.orange);
      return;
    }

    final dynamic rawId = item['id'];
    if (rawId == null) {
      _showSnackBar("Lỗi: Mã sản phẩm không hợp lệ!", Colors.red);
      return;
    }

    final int itemId = (rawId is num) ? rawId.toInt() : int.tryParse(rawId.toString()) ?? 0;

    if (itemId == 0) {
      _showSnackBar("Lỗi: Dữ liệu ID không thể định dạng!", Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReturnScreen(
          accessToken: widget.accessToken,
          orderItemId: itemId,
          userId: _userId!,
        ),
      ),
    ).then((value) {
      if (value == true) _handleRefresh();
    });
  }
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}