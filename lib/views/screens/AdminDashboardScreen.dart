import 'package:flutter/material.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../data/models/user_model.dart';
import '../../data/models/seller_registration_model.dart';
import '../../widgets/custom_admin_app_bar.dart';
import '../../widgets/user_tile.dart';
import '../widgets/product_list_for_shop.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String accessToken;
  const AdminDashboardScreen({super.key, required this.accessToken});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserRemoteDataSource _dataSource = UserRemoteDataSource();

  List<UserModel> _users = [];
  List<SellerRegistration> _shops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await _dataSource.getAllUsers(widget.accessToken);
      final shops = await _dataSource.getAllShops(widget.accessToken);
      setState(() {
        _users = users;
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
      setState(() => _isLoading = false);
    }
  }

  // Hàm xử lý khóa/mở khóa đã được gộp lại duy nhất 1 hàm
  Future<void> _blockUser(int id, bool currentStatus) async {
    try {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(currentStatus ? "Khóa tài khoản" : "Mở khóa tài khoản"),
          content: Text("Bạn có chắc chắn muốn ${currentStatus ? 'khóa' : 'mở khóa'} tài khoản này?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Đồng ý")),
          ],
        ),
      );

      if (confirm == true) {
        await _dataSource.blockUser(widget.accessToken, id, !currentStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thao tác thành công")));
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _closeShop(int id) async {
    try {
      await _dataSource.closeShop(widget.accessToken, id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đóng shop thành công")));
      _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: const CustomAdminAppBar(title: "Quản trị Hệ thống"),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatCard("Tổng User", "${_users.length}", Icons.people, Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard("Tổng Shop", "${_shops.length}", Icons.storefront, Colors.orange),
                    const SizedBox(width: 16),
                    _buildStatCard("Đang chờ duyệt", "5", Icons.pending_actions, Colors.red),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildManagementSection("Quản lý User", Icons.manage_accounts, _buildUserList())),
                      const SizedBox(width: 16),
                      Expanded(child: _buildManagementSection("Quản lý Shop", Icons.store, _buildShopList())),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        return UserTile(
          user: _users[index],
          onUpdate: _handleUpdateUser,
          onBlock: (id) => _blockUser(id, _users[index].enabled),
        );
      },
    );
  }

  Widget _buildShopList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _shops.length,
      itemBuilder: (context, index) {
        final s = _shops[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const Icon(Icons.store, color: Colors.orange),
            title: Text(
                s.shopName,
                style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            subtitle: Text(s.address),
            trailing: ElevatedButton.icon(
              icon: const Icon(Icons.close, size: 16),
              label: const Text("Đóng Shop"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red,
                elevation: 0,
              ),
              onPressed: () => _closeShop(s.id),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)), child: ListTile(leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color)), title: Text(title, style: const TextStyle(color: Colors.grey)), subtitle: Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)))));
  }

  Widget _buildManagementSection(String title, IconData icon, Widget list) {
    return Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)), child: Column(children: [Padding(padding: const EdgeInsets.all(16), child: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))])), const Divider(height: 1), Expanded(child: list)]));
  }

  Future<void> _handleUpdateUser(
      int userId, String name, String phone, String province, String district, String ward, String street, String house
      ) async {
    try {
      final updateData = {
        "fullName": name,
        "phone": phone,
        "province": province,
        "district": district,
        "ward": ward,
        "street": street,
        "houseNumber": house
      };

      await _dataSource.updateUserByAdmin(widget.accessToken, userId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thông tin thành công!"), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi cập nhật: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
}
