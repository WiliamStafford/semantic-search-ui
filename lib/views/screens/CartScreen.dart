import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../core/utils/format_utils.dart';
import '../theme/fruit_colors.dart';
import 'OrderScreen..dart';
import '../../data/models/cart_model.dart';
import '../../data/datasource/user_remote_data_source.dart';
class CartScreen extends StatefulWidget {
  final String accessToken;

  const CartScreen({super.key, required this.accessToken});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<int> _selectedItems = {};
  late Future<CartResponse> _cartFuture;
  int? _dynamicUserId;
  bool _isLoadingUser = true;

  final String baseUrl = 'https://napping-squash-majorette.ngrok-free.dev/api/v1/cart';

  @override
  void initState() {
    super.initState();
    _fetchUserAndCart();
  }

  Future<void> _fetchUserAndCart() async {
    try {
      final userProfile = await UserRemoteDataSource().getUserProfile(widget.accessToken);
      if (mounted) {
        setState(() {
          _dynamicUserId = userProfile.id;
          _isLoadingUser = false;
          _loadCart();
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy thông tin người dùng: $e");
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  void _loadCart() {
    if (_dynamicUserId != null) {
      setState(() {
        _cartFuture = fetchCart(_dynamicUserId!);
      });
    }
  }

  double _calculateSelectedTotal(List<CartItem> items) {
    return items
        .where((item) => _selectedItems.contains(item.sellerProductId))
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  Future<CartResponse> fetchCart(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/summary?userId=$userId'),
      headers: {
        'ngrok-skip-browser-warning': 'any',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );

    if (response.statusCode == 200) {
      return CartResponse.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Không thể tải dữ liệu giỏ hàng từ Server');
    }
  }

  Future<void> updateQuantity(int productId, int delta) async {
    if (_dynamicUserId == null) return;

    final response = await http.put(
      Uri.parse('$baseUrl/update-quantity?userId=$_dynamicUserId&sellerProductId=$productId&delta=$delta'),
      headers: {
        'ngrok-skip-browser-warning': 'any',
        'Authorization': 'Bearer ${widget.accessToken}',
      },
    );
    if (response.statusCode == 200) {
      _loadCart();
    }
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
            child: _dynamicUserId == null
                ? _buildErrorState("Không thể xác định danh tính người dùng.")
                : FutureBuilder<CartResponse>(
              future: _cartFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen));
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                } else if (snapshot.hasData) {
                  final cart = snapshot.data!;
                  if (cart.items.isEmpty) return _buildEmptyCart();

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(32),
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) => _buildCartItem(cart.items[index]),
                        ),
                      ),
                      _buildSummarySection(cart.items),
                    ],
                  );
                }
                return const SizedBox();
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
          Text("Giỏ hàng FruitFresh",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
          Spacer(),
          Icon(Icons.shopping_cart_checkout, color: FruitColors.accentGreen),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    bool isSelected = _selectedItems.contains(item.sellerProductId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: FruitColors.accentGreen, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: FruitColors.accentGreen,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _selectedItems.add(item.sellerProductId);
                } else {
                  _selectedItems.remove(item.sellerProductId);
                }
              });
            },
          ),
          // Trong CartScreen.dart, tại widget _buildCartItem
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (item.imageUrl.isNotEmpty)
                ? Image.network(
              item.imageUrl,
              width: 80, height: 80, fit: BoxFit.cover,
            )
                : const SizedBox(
              width: 80, height: 80,
              child: Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text("${FormatUtils.vnCurrency.format(item.price)}đ",
                    style: const TextStyle(color: FruitColors.accentGreen, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Row(
            children: [
              _qtyBtn(Icons.remove, () => updateQuantity(item.sellerProductId, -1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("${item.quantity}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              _qtyBtn(Icons.add, () => updateQuantity(item.sellerProductId, 1), isAdd: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap, {bool isAdd = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isAdd ? FruitColors.primaryGreen : FruitColors.softGreen.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isAdd ? Colors.white : FruitColors.primaryGreen, size: 16),
      ),
    );
  }

  Widget _buildSummarySection(List<CartItem> allItems) {
    double selectedTotal = _calculateSelectedTotal(allItems);
    List<CartItem> selectedData = allItems
        .where((item) => _selectedItems.contains(item.sellerProductId))
        .toList();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Đã chọn ${_selectedItems.length} sản phẩm", style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Text("${FormatUtils.vnCurrency.format(selectedTotal)}",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
            ],
          ),
          ElevatedButton(
            onPressed: _selectedItems.isEmpty
                ? null
                : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderScreen(
                    accessToken: widget.accessToken,
                    selectedItems: selectedData,
                    totalAmount: selectedTotal,
                  ),
                ),
              ).then((_) {
                setState(() {
                  _selectedItems.clear();
                });
                _loadCart();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FruitColors.accentGreen,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: const Text("TIẾP TỤC THANH TOÁN",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: FruitColors.softGreen.withOpacity(0.5)),
          const SizedBox(height: 24),
          const Text("Giỏ hàng của bạn đang trống.", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text("Lỗi: $error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
    ),
  );
}