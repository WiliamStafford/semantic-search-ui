import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/utils/format_utils.dart';
import '../../data/datasource/ProductRemoteDataSource.dart';
import '../theme/fruit_colors.dart';
import '../../data/models/product_model.dart';
import '../../data/models/user_model.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../views/screens/product_detail_screen.dart';
import '../../data/datasource/cart_remote_data_source.dart';

class FruitHomeScreen extends StatefulWidget {
  final String accessToken;
  const FruitHomeScreen({super.key, required this.accessToken});

  @override
  State<FruitHomeScreen> createState() => _FruitHomeScreenState();
}

class _FruitHomeScreenState extends State<FruitHomeScreen> {

  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  String selectedCategory = "Tất cả";

  final Map<int, bool> _localFavorites = {};

  late Future<List<ProductModel>> _productsFuture;
  late Future<UserModel> _userFuture;

  bool _isSearchingAI = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    setState(() {
      _localFavorites.clear();
      _isSearchingAI = false;
      _productsFuture = ProductRemoteDataSource().getHomeProducts(widget.accessToken);
      _userFuture = UserRemoteDataSource().getUserProfile(widget.accessToken);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<ProductModel>> _executeHomeSemanticSearch(String query, {int? categoryId}) async {
    if (query.trim().isEmpty) {
      _loadInitialData();
      return [];
    }

    final Map<String, dynamic> queryParams = {
      'q': query,
      'page': '0',
      'size': '20',
    };

    if (categoryId != null && categoryId > 0) {
      queryParams['categoryId'] = categoryId.toString();
    }

    final uri = Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/products/semantic-search')
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'ngrok-skip-browser-warning': 'any',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResult = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> rawList = jsonResult['productsList'] ?? jsonResult['products'] ?? [];
      debugPrint("Raw Item từ AI: ${rawList.isNotEmpty ? rawList[0] : 'Empty'}");
      return rawList.map((item) => ProductModel(
        id: item['id'] ?? 0,
        sellerProductId: item['id'] ?? 0,
        productName: item['productName'] ?? 'Nông sản an toàn',
        price: (item['price'] is num) ? (item['price'] as num).toDouble() : 0.0,
        avatar: item['avatar'],
        isFavorite: false,
      )).toList();
    } else {
      throw Exception('Không thể kết nối máy chủ tìm kiếm AI');
    }
  }

  void _triggerSearch(String text) {
    if (text.trim().isEmpty) {
      _loadInitialData();
    } else {
      setState(() {
        _isSearchingAI = true;
        _productsFuture = _executeHomeSemanticSearch(text);
      });
    }
  }


  Future<void> _toggleWishlist(ProductModel product) async {
    final bool isCurrentlyFav = _localFavorites[product.sellerProductId] ?? product.isFavorite;

    setState(() {
      _localFavorites[product.sellerProductId] = !isCurrentlyFav;
    });

    try {
      final url = 'https://napping-squash-majorette.ngrok-free.dev/api/v1/wishlist/${product.sellerProductId}/toggle';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'ngrok-skip-browser-warning': 'any',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          _localFavorites[product.sellerProductId] = isCurrentlyFav;
        });
      }
    } catch (e) {
      setState(() {
        _localFavorites[product.sellerProductId] = isCurrentlyFav;
      });
    }
  }

  Future<void> _handleAddToCart(ProductModel product) async {
    try {
      final user = await UserRemoteDataSource().getUserProfile(widget.accessToken);
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBanner(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                          _isSearchingAI ? Icons.auto_awesome : Icons.stars_outlined,
                          color: FruitColors.primaryGreen,
                          size: 18
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSearchingAI ? "Kết quả gợi ý thông minh từ AI" : "Sản phẩm gợi ý cho bạn",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (_isSearchingAI) ...[
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _loadInitialData,
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.grey),
                          label: const Text("Quay lại mặc định", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProductSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return FutureBuilder<List<ProductModel>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: FruitColors.accentGreen),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
            ),
          );
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.search_off_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text("Không tìm thấy sản phẩm nào phù hợp với nhu cầu của bạn.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildProductCard(products[index]),
        );
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    bool isFav = _localFavorites[product.sellerProductId] ?? product.isFavorite;

    return InkWell(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FruitColors.softGreen.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FBF7),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.avatar != null
                      ? Image.network(product.avatar!, fit: BoxFit.cover)
                      : const Icon(Icons.eco_outlined, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${FormatUtils.vnCurrency.format(product.price)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: FruitColors.accentGreen, fontSize: 13),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleWishlist(product),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.pinkAccent : Colors.grey[400],
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _handleAddToCart(product),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: FruitColors.primaryGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 12),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                  color: FruitColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: FruitColors.softGreen)
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: _triggerSearch,
                decoration: InputDecoration(
                    hintText: "Tìm rau, củ, hạt thông minh bằng AI (Ví dụ: hạt tốt cho bà bầu)...",
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, size: 18),
                      onPressed: () => _triggerSearch(_searchController.text),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10)
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          _buildUserMiniProfile(),
        ],
      ),
    );
  }

  Widget _buildUserMiniProfile() {
    return FutureBuilder<UserModel>(
      future: _userFuture,
      builder: (context, snapshot) {
        String name = snapshot.hasData ? snapshot.data!.fullName : "Guest";
        String? avatar = snapshot.hasData ? snapshot.data!.avatar : null;
        return Row(
          children: [
            Text("Chào, $name!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 12),
            CircleAvatar(radius: 16, backgroundImage: avatar != null ? NetworkImage(avatar) : null, child: avatar == null ? const Icon(Icons.person, size: 18) : null),
          ],
        );
      },
    );
  }

  Widget _buildBanner() => Container(
    width: double.infinity, height: 130,
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [FruitColors.primaryGreen, FruitColors.accentGreen]), borderRadius: BorderRadius.circular(16)),
    child: const Padding(padding: EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text("Nông sản xanh sạch mỗi ngày", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text("Hỗ trợ tìm kiếm thông minh bằng mô hình AI ngữ nghĩa", style: TextStyle(color: Colors.white70, fontSize: 13))])),
  );
}