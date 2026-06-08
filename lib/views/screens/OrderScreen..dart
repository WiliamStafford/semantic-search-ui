import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/format_utils.dart';
import '../theme/fruit_colors.dart';
import '../../data/models/cart_model.dart';
import '../../data/datasource/user_remote_data_source.dart';

class OrderScreen extends StatefulWidget {
  final String accessToken;
  final List<CartItem> selectedItems;
  final double totalAmount;

  const OrderScreen({
    super.key,
    required this.accessToken,
    required this.selectedItems,
    required this.totalAmount,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _addressController = TextEditingController();
  String _paymentMethod = "COD"; // Các giá trị hợp lệ: COD, VNPAY, PAYPAL
  bool _isProcessing = false;

  Future<void> _handlePlaceOrder() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập địa chỉ giao hàng!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = await UserRemoteDataSource().getUserProfile(widget.accessToken);

      // Gọi API đặt hàng
      final orderResponse = await http.post(
        Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/orders/buy-now'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
          'ngrok-skip-browser-warning': 'any',
        },
        body: jsonEncode({
          "userId": user.id,
          "shippingAddress": _addressController.text.trim(),
          "totalPrice": widget.totalAmount,
          "items": widget.selectedItems.map((item) => {
            "sellerProductId": item.sellerProductId,
            "quantity": item.quantity,
            "price": item.price
          }).toList(),
        }),
      );

      // 🌟 KIỂM TRA STATUS CODE ĐỂ TRÁNH LỖI FORMATEXCEPTION (SYNTAX ERROR)
      if (orderResponse.statusCode == 200 || orderResponse.statusCode == 201) {
        final orderData = jsonDecode(utf8.decode(orderResponse.bodyBytes));
        final int orderId = orderData['id'];
        final double totalPrice = (orderData['totalPrice'] as num).toDouble();

        if (_paymentMethod == "COD") {
          _showSuccessDialog("Đặt hàng thành công! Đơn hàng đang được xử lý.");
          return;
        }

        // Logic thanh toán online
        final paymentResponse = await http.post(
          Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/payments/init'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.accessToken}',
            'ngrok-skip-browser-warning': 'any',
          },
          body: jsonEncode({
            "orderId": orderId,
            "amount": totalPrice.toInt(),
            "provider": _paymentMethod
          }),
        );

        if (paymentResponse.statusCode == 200) {
          final paymentData = jsonDecode(paymentResponse.body);
          final String? paymentUrl = paymentData['paymentUrl'];

          if (paymentUrl != null && paymentUrl.isNotEmpty) {
            final Uri url = Uri.parse(paymentUrl);
            if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
              if (!mounted) return;
              _showWaitingPaymentDialog();
            } else {
              throw Exception('Không thể mở trang liên kết thanh toán');
            }
          } else {
            throw Exception('Hệ thống không phản hồi đường dẫn thanh toán');
          }
        } else {
          throw Exception("Lỗi cổng thanh toán: ${paymentResponse.statusCode}");
        }
      } else {
        debugPrint("Lỗi Backend (${orderResponse.statusCode}): ${orderResponse.body}");
        throw Exception("Lỗi tạo đơn hàng: ${orderResponse.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi hệ thống: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showWaitingPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Ép người dùng phải bấm nút xác nhận, không bấm lệch ra ngoài để tắt được
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            CircularProgressIndicator(color: FruitColors.accentGreen),
            SizedBox(width: 20),
            Text("Đang chờ thanh toán...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Vui lòng hoàn tất giao dịch tại cửa sổ trình duyệt vừa được mở.\nSau khi hoàn thành, hãy ấn nút xác nhận bên dưới.",
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Đóng hộp thoại dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Quay phắt về trang chính, giỏ hàng sẽ tự tải lại mất 2 món vừa mua
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: FruitColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                ),
                child: const Text("TÔI ĐÃ THANH TOÁN XONG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text("Xử lý thành công!"),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              style: ElevatedButton.styleFrom(backgroundColor: FruitColors.primaryGreen),
              child: const Text("QUAY VỀ TRANG CHỦ", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 FIXED: Đã lột bỏ Row bọc thanh SharedSidebar lồng cũ để đưa về dạng nội dung độc lập phẳng hoàn toàn
    return Scaffold(
      backgroundColor: FruitColors.background,
      appBar: AppBar(
        title: const Text("Xác nhận & Cổng thanh toán", style: TextStyle(color: FruitColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: FruitColors.primaryGreen),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildLeftSection()),
            const SizedBox(width: 32),
            Expanded(flex: 1, child: _buildRightSection()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Địa chỉ nhận hàng", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Nhập địa chỉ giao hàng chi tiết...",
                  border: OutlineInputBorder(),
                  fillColor: Color(0xFFF9FBF7),
                  filled: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chọn hình thức thanh toán", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
              const SizedBox(height: 12),
              _buildPaymentRadio("COD", "Thanh toán trực tiếp khi nhận hàng (COD)", Icons.local_shipping),
              const Divider(),
              _buildPaymentRadio("VNPAY", "Thanh toán điện tử qua Cổng VNPAY", Icons.account_balance),
              const Divider(),
              _buildPaymentRadio("PAYPAL", "Thanh toán Quốc tế qua PayPal", Icons.payment),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPaymentRadio(String value, String title, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          Icon(icon, color: FruitColors.primaryGreen, size: 22),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
      value: value,
      groupValue: _paymentMethod,
      activeColor: FruitColors.primaryGreen,
      onChanged: (val) => setState(() => _paymentMethod = val!),
    );
  }

  Widget _buildRightSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Sản phẩm thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
          const Divider(height: 32),

          ...widget.selectedItems.map((item) {
            // 🌟 Tinh chỉnh: Kiểm tra cả null và rỗng để tránh lỗi icon
            final bool hasImage = item.imageUrl.isNotEmpty;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                      // Chỉ render ảnh nếu URL không trống
                      image: hasImage
                          ? DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover)
                          : null,
                    ),
                    // Hiển thị icon thay thế nếu không có ảnh
                    child: !hasImage ? const Icon(Icons.image_not_supported, color: Colors.grey) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text("Số lượng: ${item.quantity}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    "${FormatUtils.vnCurrency.format(item.price * item.quantity)}đ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: FruitColors.primaryGreen),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng tiền", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                "${FormatUtils.vnCurrency.format(widget.totalAmount)}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FruitColors.accentGreen),
              ),
            ],
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: FruitColors.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("TIẾN HÀNH ĐẶT HÀNG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}