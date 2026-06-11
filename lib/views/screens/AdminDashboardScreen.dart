import 'package:flutter/material.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../data/models/user_model.dart';
import '../../data/models/seller_registration_model.dart';
import '../../widgets/custom_admin_app_bar.dart';

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

  Future<void> _blockUser(int id) async {
    try {
      await _dataSource.blockUser(widget.accessToken, id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã khóa tài khoản thành công")));
      _loadData(); // Tải lại danh sách
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _closeShop(int id) async {
    try {
      await _dataSource.closeShop(widget.accessToken, id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đóng shop thành công")));
      _loadData(); // Tải lại danh sách
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
        final u = _users[index];
        return ExpansionTile(
          leading: const Icon(Icons.person),
          title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(u.email),
          children: [
            ListTile(title: Text("Điện thoại: ${u.phone ?? 'N/A'}")),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                onPressed: () => _blockUser(u.id),
                child: const Text("Khóa tài khoản"),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShopList() {
    return ListView.builder(
      itemCount: _shops.length,
      itemBuilder: (context, index) {
        final s = _shops[index];
        return ExpansionTile(
          leading: const Icon(Icons.store),
          title: Text(s.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(s.address),
          children: [
            ListTile(title: Text("Mô tả: ${s.description ?? 'Không có mô tả'}")),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red),
                onPressed: () => _closeShop(s.id),
                child: const Text("Đóng Shop"),
              ),
            ),
          ],
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
}