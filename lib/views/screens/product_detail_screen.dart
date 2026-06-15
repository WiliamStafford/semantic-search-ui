import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../core/utils/format_utils.dart';
import '../../data/datasource/cart_remote_data_source.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../theme/fruit_colors.dart';
import '../../config/app_config.dart';
import '../../data/models/cart_model.dart';
import 'OrderScreen..dart';
import '../../features/chat/presentation/pages/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int sellerProductId;
  final String accessToken;


  const ProductDetailScreen({
    Key? key,
    required this.sellerProductId,
    required this.accessToken,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<Map<String, dynamic>> _detailFuture;
  int quantity = 1;
  String selectedSize = '';
  List<String> productSizes = [];

  @override
  void initState() {
    super.initState();
    _detailFuture = _fetchProductDetail(widget.sellerProductId);
  }
  Future<String?> _fetchSellerName(int sellerId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/api/v1/sellers/$sellerId'),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes))['name'];
      }
    } catch (e) {
      return "Người bán";
    }
    return "Người bán";
  }

  Future<Map<String, dynamic>> _fetchProductDetail(int id) async {
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/v1/products/detail/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));

      String sizesStr = data['size'] ?? data['note'] ?? '';
      if (sizesStr.isNotEmpty) {
        setState(() {
          productSizes = sizesStr.split(',');
          if (productSizes.isNotEmpty) selectedSize = productSizes[0].trim();
        });
      }
      return data;
    } else {
      throw Exception('Lỗi ${response.statusCode}: Không thể lấy thông tin sản phẩm.');
    }
  }

  Future<void> _handleAddToCart() async {
    try {
      final user = await UserRemoteDataSource().getUserProfile(widget.accessToken);

      final success = await CartRemoteDataSource().addToCart(
        token: widget.accessToken,
        userId: user.id,
        sellerProductId: widget.sellerProductId,
        quantity: quantity,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(" Đã thêm vào giỏ hàng thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: FruitColors.primaryGreen),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text("Chi tiết sản phẩm",
            style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FruitColors.primaryGreen));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (snapshot.hasData) {
            return _buildMainLayout(snapshot.data!);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMainLayout(Map<String, dynamic> product) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 400,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBF7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: product['avatar'] != null
                            ? Image.network(product['avatar'], fit: BoxFit.contain)
                            : const Icon(Icons.apple, size: 100, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),

                  Expanded(
                    flex: 6,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['productName'] ?? 'Sản phẩm không tên',
                            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Text("Mã SP: ${product['sku'] ?? 'N/A'}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(width: 15),
                            _buildBadge("Seller ID: ${product['sellerId']}", Colors.blue),
                            const SizedBox(width: 10),
                            _buildBadge("Chính hãng", Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text('${FormatUtils.vnCurrency.format(product['price'] ?? 0)}',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: FruitColors.accentGreen)),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(),
                        ),

                        if (productSizes.isNotEmpty) ...[
                          const Text("Phân loại / Size", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: productSizes.map((s) => ChoiceChip(
                              label: Text(s.trim()),
                              selected: selectedSize == s.trim(),
                              onSelected: (val) => setState(() => selectedSize = s.trim()),
                              selectedColor: FruitColors.accentGreen,
                              labelStyle: TextStyle(color: selectedSize == s.trim() ? Colors.white : Colors.black),
                            )).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        const Text("Số lượng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildQtySelector(),
                            const SizedBox(width: 20),
                            Text("Còn lại: ${product['stock'] ?? 0} sản phẩm", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),

                        const SizedBox(height: 40),

                        Row(
                          children: [
                            // Nút Chat mới đã sửa lỗi tham số
                            IconButton(
                              onPressed: () => _handleChatPress(
                                product['sellerId'],
                                product['sellerName']?.toString() ?? "Người bán",
                                product,
                              ),
                              icon: const Icon(Icons.chat_bubble_outline, color: FruitColors.primaryGreen),
                              tooltip: "Chat với người bán",
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: _buildActionBtn("THÊM VÀO GIỎ", isPrimary: false, product: product)),
                            const SizedBox(width: 15),
                            Expanded(child: _buildActionBtn("MUA NGAY", isPrimary: true, product: product)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),

              const Text("Mô tả sản phẩm", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 15),
              Text(
                product['description'] ?? "Thông tin mô tả sản phẩm đang được cập nhật. Sản phẩm đảm bảo tiêu chuẩn tươi sạch, đạt chứng nhận an toàn thực phẩm.",
                style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildQtySelector() {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: () => setState(() { if (quantity > 1) quantity--; })),
          Text("$quantity", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          IconButton(icon: const Icon(Icons.add, size: 18), onPressed: () => setState(() => quantity++)),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String text, {required bool isPrimary, required Map<String, dynamic> product}) {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: () async { // 🌟 Thêm async ở đây
          if (!isPrimary) {
            _handleAddToCart();
          } else {
            // 1. Thêm vào giỏ hàng trước
            await _handleAddToCart();

            double price = (product['price'] as num?)?.toDouble() ?? 0.0;
            CartItem tempItem = CartItem(
              id: 0,
              sellerProductId: widget.sellerProductId,
              productName: product['productName'] ?? 'Sản phẩm không tên',
              price: price,
              imageUrl: product['avatar'] ?? '',
              quantity: quantity,
              sellerId: (product['sellerId'] as num?)?.toInt() ?? 0,
            );

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderScreen(
                    accessToken: widget.accessToken,
                    selectedItems: [tempItem],
                    totalAmount: price * quantity,
                  ),
                ),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? FruitColors.primaryGreen : Colors.white,
          foregroundColor: isPrimary ? Colors.white : FruitColors.primaryGreen,
          elevation: 0,
          side: isPrimary ? null : const BorderSide(color: FruitColors.primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại")),
        ],
      ),
    );
  }
  // ... (các đoạn code trên giữ nguyên)

  Future<void> _handleChatPress(int sellerId, String sellerName, Map<String, dynamic> product) async {
    // 1. Kiểm tra dữ liệu an toàn trước khi gọi API
    final int? productSellerId = product['id'] ?? widget.sellerProductId;

    if (productSellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lỗi: Không tìm thấy thông tin sản phẩm!"), backgroundColor: Colors.red),
      );
      return;
    }

    print("DEBUG: Khởi tạo chat với sellerId: $sellerId, productSellerId: $productSellerId");

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/v1/chat/start'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        // 2. Gửi thêm productSellerId lên Backend
        body: jsonEncode({
          'sellerId': sellerId,
          'productSellerId': productSellerId
        }),
      );

      if (response.statusCode == 200) {
        final dynamic convData = jsonDecode(response.body);
        final int conversationId = (convData is int) ? convData : int.parse(convData.toString());

        final user = await UserRemoteDataSource().getUserProfile(widget.accessToken);

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                senderId: user.id,
                receiverId: sellerId,
                token: widget.accessToken,
                sellerName: sellerName,
                product: product,
              ),
            ),
          );
        }
      } else {
        throw Exception("Không thể khởi tạo chat");
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi chat: $e"), backgroundColor: Colors.red));
    }
  }

}