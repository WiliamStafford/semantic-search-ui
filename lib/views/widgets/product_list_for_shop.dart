import 'package:flutter/material.dart';
import '../../../data/datasource/user_remote_data_source.dart';
import '../../../data/models/product_model.dart';
import '../../data/models/product_model.dart';
class ProductListForShop extends StatefulWidget {
  final String accessToken;
  final int sellerId;

  const ProductListForShop({
    super.key,
    required this.accessToken,
    required this.sellerId,
  });

  @override
  State<ProductListForShop> createState() => _ProductListForShopState();
}

class _ProductListForShopState extends State<ProductListForShop> {
  final UserRemoteDataSource _dataSource = UserRemoteDataSource();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    print("DEBUG: Đang lấy sản phẩm cho SellerID: ${widget.sellerId}");

    try {
      final products = await _dataSource.getProductsBySeller(widget.accessToken, widget.sellerId);

      print("DEBUG: Nhận được ${products.length} sản phẩm từ server.");

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("DEBUG: Lỗi khi lấy sản phẩm: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(int productId) async {
    // Xác nhận xóa
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dataSource.deleteSellerProduct(widget.accessToken, productId);
        if (mounted) {
          setState(() => _products.removeWhere((p) => p.id == productId));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa sản phẩm")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi xóa: $e")));
      }
    }
  }

  // TODO: Implement logic edit tại đây
  void _editProduct(ProductModel product) {
    // Mở Dialog chứa form cập nhật giá/số lượng
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator()));
    if (_products.isEmpty) return const Padding(padding: EdgeInsets.all(16.0), child: Text("Shop chưa có sản phẩm"));

    return Column(
      children: _products.map((p) => ListTile(
        leading: const Icon(Icons.shopping_bag_outlined),
        title: Text(p.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text("Giá: ${p.price} |Tồn: ${p.stock}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.blue), onPressed: () => _editProduct(p)),
            IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => _deleteProduct(p.id)),
          ],
        ),
      )).toList(),
    );
  }
}