import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Bắt buộc có để dùng inputFormatters
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../theme/fruit_colors.dart';
import '../../data/models/user_model.dart';
import '../../data/datasource/user_remote_data_source.dart';

class FruitProfileScreen extends StatefulWidget {
  final String accessToken;
  const FruitProfileScreen({super.key, required this.accessToken});

  @override
  State<FruitProfileScreen> createState() => _FruitProfileScreenState();
}

class _FruitProfileScreenState extends State<FruitProfileScreen> {
  late Future<UserModel> _userProfile;
  bool isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _loadProfile() {
    setState(() {
      _userProfile = UserRemoteDataSource().getUserProfile(widget.accessToken);
    });

    _userProfile.then((user) {
      _nameController.text = user.fullName;
      _phoneController.text = user.phone ?? "";
      _ageController.text = user.age?.toString() ?? "";
    });
  }

  Future<void> _handleUpdate() async {
    try {
      final updateData = {
        "fullName": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()),
        "avatar": null
      };

      await UserRemoteDataSource().updateProfile(widget.accessToken, updateData);

      setState(() {
        isEditing = false;
        _loadProfile();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("  Cập nhật thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("  Lỗi: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: FutureBuilder<UserModel>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !isEditing) {
            return const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen));
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return const Center(child: Text("Không tìm thấy dữ liệu người dùng"));
          }

          final user = snapshot.data!;
          return Row(
            children: [
              Container(
                width: 240,
                color: FruitColors.primaryGreen,
                child: _buildSidebar(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),
                      _buildProfileSection(user),
                      const SizedBox(height: 24),
                      _buildOrderHistory(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: _boxDecoration(),
          child: Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: FruitColors.accentGreen,
                backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                child: user.avatar == null
                    ? Text(user.fullName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 34, color: FruitColors.lightGreen))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(user.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FruitColors.primaryGreen)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: user.roles.map((role) => _buildRoleBadge(role)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Thông tin định danh",
                    style: TextStyle(fontWeight: FontWeight.bold, color: FruitColors.accentGreen)),
                const Divider(height: 32),

                _infoRow("Họ và tên", user.fullName, controller: _nameController, icon: Icons.person_outline),
                _infoRow("Địa chỉ Email", user.email, icon: Icons.email_outlined, canEdit: false),

                _infoRow("Số điện thoại", user.phone ?? "Chưa cập nhật",
                    controller: _phoneController, icon: Icons.phone_android, isNumberOnly: true),

                _infoRow("Tuổi", user.age?.toString() ?? "N/A",
                    controller: _ageController, icon: Icons.cake_outlined, isNumberOnly: true),

                _infoRow("Ngày tham gia", DateFormat('dd/MM/yyyy').format(user.createdAt), icon: Icons.calendar_today_outlined, canEdit: false),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    if (isEditing) {
                      _handleUpdate();
                    } else {
                      setState(() => isEditing = true);
                    }
                  },
                  icon: Icon(isEditing ? Icons.check : Icons.edit, size: 18, color: Colors.white),
                  label: Text(isEditing ? "Xác nhận thay đổi" : "Cập nhật thông tin",
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditing ? Colors.orange : FruitColors.accentGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    elevation: 0,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {
    IconData? icon,
    TextEditingController? controller,
    bool canEdit = true,
    bool isNumberOnly = false,
    int? maxLength, // Thêm tham số giới hạn độ dài
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Căn chỉnh để không bị lệch khi hiện counter
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Icon(icon, size: 20, color: Colors.grey[400]),
          ),
          const SizedBox(width: 12),
          SizedBox(
              width: 150,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              )
          ),
          Expanded(
            child: (isEditing && canEdit)
                ? TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              keyboardType: isNumberOnly ? TextInputType.number : TextInputType.text,
              maxLength: maxLength,
              inputFormatters: [
                if (isNumberOnly) FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                counterText: "",
              ),
            )
                : Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Sidebar, Header, etc. ---
  Widget _buildSidebar() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              const Icon(Icons.eco, color: FruitColors.lightGreen),
              const SizedBox(width: 8),
              Text("FruitFresh", style: TextStyle(color: FruitColors.lightGreen, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        _navItem(Icons.home_outlined, "Trang chủ"),
        _navItem(Icons.shopping_bag_outlined, "Sản phẩm"),
        _navItem(Icons.person, "Hồ sơ cá nhân", isActive: true),
        _navItem(Icons.history, "Đơn hàng"),
        const Spacer(),
        _navItem(
          Icons.logout,
          "Đăng xuất",
          onTap: () async {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _navItem(IconData icon, String title, {bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: isActive ? FruitColors.lightGreen : Colors.white60, size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isActive ? FruitColors.lightGreen : Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Hồ sơ cá nhân", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
      Text("Thông tin chi tiết tài khoản của bạn trên hệ thống", style: TextStyle(color: Colors.grey, fontSize: 14)),
    ],
  );

  Widget _buildRoleBadge(String roleName) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFFEAF3DE), borderRadius: BorderRadius.circular(12), border: Border.all(color: FruitColors.softGreen)),
    child: Text(roleName.replaceAll("ROLE_", ""), style: const TextStyle(fontSize: 10, color: FruitColors.accentGreen, fontWeight: FontWeight.bold)),
  );

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
    border: Border.all(color: FruitColors.lightGreen.withOpacity(0.5)),
  );

  Widget _buildOrderHistory() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: _boxDecoration(),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Đơn hàng gần đây", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        SizedBox(height: 16),
        Text("Tính năng lịch sử đơn hàng đang được cập nhật...", style: TextStyle(color: Colors.grey)),
      ],
    ),
  );

  Widget _buildErrorState(String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text("Lỗi: $error"),
        ElevatedButton(onPressed: _loadProfile, child: const Text("Thử lại")),
      ],
    ),
  );
}