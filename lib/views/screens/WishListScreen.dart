import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/utils/format_utils.dart';
import '../theme/fruit_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../data/datasource/cart_remote_data_source.dart';
import '../../views/screens/product_detail_screen.dart';

class WishListScreen extends StatefulWidget {
  final String accessToken;

  const WishListScreen({super.key, required this.accessToken});

  @override
  State<WishListScreen> createState() => _WishListScreenState();
}

class _WishListScreenState extends State<WishListScreen> {
  List<ProductModel> _favoriteProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'https://napping-squash-majorette.ngrok-free.dev/api/v1/wishlist/my-list',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'ngrok-skip-browser-warning': 'any',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _favoriteProducts = data
              .map((json) => ProductModel.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception("Lỗi tải danh sách");
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Không thể kết nối danh sách yêu thích!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveFavorite(ProductModel product, int index) async {
    setState(() {
      _favoriteProducts.removeAt(index);
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://napping-squash-majorette.ngrok-free.dev/api/v1/wishlist/${product.sellerProductId}/toggle',
        ),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode != 200) {
        setState(() {
          _favoriteProducts.insert(index, product);
        });
      }
    } catch (e) {
      setState(() {
        _favoriteProducts.insert(index, product);
      });
    }
  }

  Future<void> _handleAddToCart(ProductModel product) async {
    try {
      final user = await UserRemoteDataSource().getUserProfile(
        widget.accessToken,
      );
      final success = await CartRemoteDataSource().addToCart(
        token: widget.accessToken,
        userId: user.id,
        sellerProductId: product.sellerProductId,
        quantity: 1,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(' Đã thêm ${product.productName} vào giỏ!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FruitColors.accentGreen,
                    ),
                  )
                : _favoriteProducts.isEmpty
                ? _buildEmptyState()
                : _buildWishlistGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: const Row(
        children: [
          Text(
            "Sản phẩm yêu thích",
            style: FruitColors.topBarTitle,
          ),
          Spacer(),
          Icon(Icons.favorite, color: Colors.pinkAccent, size: 22),
        ],
      ),
    );
  }


  Widget _buildWishlistGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.82,
      ),
      itemCount: _favoriteProducts.length,
      itemBuilder: (context, index) {
        final product = _favoriteProducts[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FruitColors.softGreen.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10),
            ],
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(
                        sellerProductId: product.sellerProductId,
                        accessToken: widget.accessToken,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FBF7),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: product.avatar != null
                              ? Image.network(
                                  product.avatar!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.eco_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${FormatUtils.vnCurrency.format(product.price)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: FruitColors.accentGreen,
                                  fontSize: 13,
                                ),
                              ),
                              InkWell(
                                onTap: () => _handleAddToCart(product),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: FruitColors.primaryGreen,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              //
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _handleRemoveFavorite(product, index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.pinkAccent,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 70,
            color: Colors.pink.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          const Text(
            "Danh sách yêu thích trống.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
