import 'package:flutter/material.dart';
import '../../data/datasource/AdminRemoteDataSource.dart';
import '../../data/models/seller_dashboard_model.dart';
import '../widgets/ProductTableWidget.dart';
import '../theme/fruit_colors.dart';

class ManageShopProductsScreen extends StatefulWidget {
  final String accessToken;
  final int sellerId;
  final String shopName;
  final VoidCallback onBack;
  const ManageShopProductsScreen({
    super.key,
    required this.accessToken,
    required this.sellerId,
    required this.shopName,
    required this.onBack,
  });

  @override
  State<ManageShopProductsScreen> createState() => _ManageShopProductsScreenState();
}

class _ManageShopProductsScreenState extends State<ManageShopProductsScreen> {
  final AdminRemoteDataSource _adminDataSource = AdminRemoteDataSource();
  late Future<SellerDashboardModel> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() {
    setState(() {
      _dashboardFuture = _adminDataSource.getSellerDashboard(widget.accessToken, widget.sellerId);
    });
  }

  // --- HÀM XÓA ---
  void _showDeleteConfirmation(BuildContext context, int productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa sản phẩm này khỏi hệ thống?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool success = await _adminDataSource.deleteProductForAdmin(widget.accessToken, widget.sellerId, productId);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa sản phẩm thành công!")));
                _loadAdminData();
              }
            },
            child: const Text("XÓA NGAY"),
          ),
        ],
      ),
    );
  }

  // --- HÀM SỬA ---
  void _showEditProductDialog(BuildContext context, SellerProductItem item) {
    final nameController = TextEditingController(text: item.productName);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chỉnh sửa nông sản (Admin)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên nông sản")),
            TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá bán")),
            TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số lượng kho")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: FruitColors.primaryGreen),
            onPressed: () async {
              final updatedData = {
                "productId": item.id,
                "name": nameController.text.trim(),
                "price": double.tryParse(priceController.text) ?? 0,
                "stock": int.tryParse(stockController.text) ?? 0,
              };

              bool success = await _adminDataSource.updateProductForAdmin(widget.accessToken, widget.sellerId, updatedData);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
                _loadAdminData();
              }
            },
            child: const Text("LƯU THAY ĐỔI"),
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
        title: Text("Quản lý Shop: ${widget.shopName}"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: FutureBuilder<SellerDashboardModel>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.productsList.isEmpty) {
            return const Center(child: Text("Shop này chưa có sản phẩm nào."));
          }
          return _buildManageView(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildManageView(SellerDashboardModel data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Text("Danh sách sản phẩm (${data.productsList.length} mặt hàng)",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),
          ProductTableWidget(
            products: data.productsList,
            onEdit: (item) => _showEditProductDialog(context, item),
            onDelete: (id) => _showDeleteConfirmation(context, id),
          ),
        ],
      ),
    );
  }
}