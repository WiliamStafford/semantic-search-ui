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
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMethod = "COD";
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }
  @override
  void dispose() {
    _addressController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    super.dispose();
  }
  Widget _buildAddressField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: FruitColors.primaryGreen.withOpacity(0.6)),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _loadUserAddress() async {
    try {
      final user = await UserRemoteDataSource().getUserProfile(widget.accessToken);
      if (mounted) {
        setState(() {
          _provinceController.text = user.province ?? "";
          _districtController.text = user.district ?? "";
          _wardController.text = user.ward ?? "";
          _streetController.text = user.street ?? "";
          _houseController.text = user.houseNumber ?? "";
        });
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
    }
  }

  Future<void> _handlePlaceOrder() async {
    if (_provinceController.text.trim().isEmpty ||
        _wardController.text.trim().isEmpty ||
        _streetController.text.trim().isEmpty ||
        _houseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin địa chỉ!"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final user = await UserRemoteDataSource().getUserProfile(widget.accessToken);

      final orderResponse = await http.post(
        Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/orders/buy-now'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.accessToken}',
          'ngrok-skip-browser-warning': 'any',
        },
        // body: jsonEncode({
        //   "userId": user.id,
        //   "sellerId": widget.selectedItems.first.sellerId,
        //   "paymentMethod": _paymentMethod,
        //   "totalPrice": widget.totalAmount,
        //   "items": widget.selectedItems.map((item) => {
        //     "sellerProductId": item.sellerProductId,
        //     "quantity": item.quantity,
        //     "price": item.price
        //   }).toList(),
        //   "newAddress": {
        //     "province": _provinceController.text.trim(),
        //     "district": "",
        //     "ward": _wardController.text.trim(),
        //     "street": _streetController.text.trim(),
        //     "houseNumber": _houseController.text.trim(),
        //   }
        // }),
        body: jsonEncode({
          "userId": user.id,
          "paymentMethod": _paymentMethod,
          "totalPrice": widget.totalAmount,
          "items": widget.selectedItems.map((item) => {
            "sellerProductId": item.sellerProductId,
            "quantity": item.quantity,
            "price": item.price
          }).toList(),
          "newAddress": {
            "province": _provinceController.text.trim(),
            "district": _districtController.text.trim(),
            "ward": _wardController.text.trim(),
            "street": _streetController.text.trim(),
            "houseNumber": _houseController.text.trim(),
          }
        }),
      );

      if (orderResponse.statusCode == 200 || orderResponse.statusCode == 201) {
        final dynamic responseBody = jsonDecode(utf8.decode(orderResponse.bodyBytes));
        final orderData = (responseBody is List) ? responseBody.first : responseBody;
        final dynamic rawId = orderData['id'];
        final int orderId = (rawId is int) ? rawId : int.tryParse(rawId.toString()) ?? 0;
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
      barrierDismissible: false, //
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FruitColors.softGreen.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Địa chỉ nhận hàng",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
              const SizedBox(height: 24),
              _buildAddressField("Tỉnh/Thành", _provinceController, Icons.map_outlined),
              _buildAddressField("Phường/Xã", _wardController, Icons.home_work_outlined),
              _buildAddressField("Đường", _streetController, Icons.signpost_outlined),
              _buildAddressField("Số nhà", _houseController, Icons.home_outlined),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // PHẦN THANH TOÁN (GIỮ NGUYÊN)
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