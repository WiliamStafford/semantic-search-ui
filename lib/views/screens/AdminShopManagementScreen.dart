import 'package:flutter/material.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../data/models/seller_registration_model.dart';
import '../theme/fruit_colors.dart';
import 'ManageShopProductsScreen.dart';

class AdminShopManagementScreen extends StatefulWidget {
  final String accessToken;
  final Function(int sellerId, String shopName) onShopSelected;
  const AdminShopManagementScreen({super.key, required this.accessToken,required this.onShopSelected,});

  @override
  State<AdminShopManagementScreen> createState() => _AdminShopManagementScreenState();
}

class _AdminShopManagementScreenState extends State<AdminShopManagementScreen> {
  final UserRemoteDataSource _dataSource = UserRemoteDataSource();
  List<SellerRegistration> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      final shops = await _dataSource.getAllShops(widget.accessToken);
      if (mounted) {
        setState(() {
          _shops = shops;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải danh sách: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: FruitColors.primaryGreen)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text("Danh sách Shop", style: TextStyle(color: Colors.white)),
        backgroundColor: FruitColors.primaryGreen,
      ),
      body: _shops.isEmpty
          ? const Center(child: Text("Hiện tại chưa có shop nào đăng ký!"))
          : RefreshIndicator(
        onRefresh: _loadShops,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _shops.length,
          itemBuilder: (context, index) {
            final s = _shops[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade50,
                    child: const Icon(Icons.store, color: Colors.orange)
                ),
                title: Text(s.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(s.address),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  widget.onShopSelected(s.userId, s.shopName);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}