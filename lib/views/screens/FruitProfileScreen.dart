import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
    }).catchError((error) {
      debugPrint("Lỗi tải profile: $error");
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
          const SnackBar(
            content: Text(" Cập nhật hồ sơ thành công!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(" Lỗi: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
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
          return Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildProfileSection(user),
                  const SizedBox(height: 40),
                  _buildOrderHistory(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HEADER SECTION ---
  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)
      ),
      const SizedBox(height: 8),
      Text(
          "Quản lý thông tin tài khoản và bảo mật của bạn",
          style: TextStyle(color: Colors.grey[600], fontSize: 16)
      ),
    ],
  );

  // --- MAIN PROFILE ---
  Widget _buildProfileSection(UserModel user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 320,
          padding: const EdgeInsets.all(40),
          decoration: _boxDecoration(),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: FruitColors.accentGreen.withOpacity(0.1),
                    backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                    child: user.avatar == null
                        ? Text(user.fullName[0].toUpperCase(),
                        style: const TextStyle(fontSize: 48, color: FruitColors.accentGreen, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  if (isEditing)
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: FruitColors.accentGreen,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    )
                ],
              ),
              const SizedBox(height: 24),
              Text(
                  user.fullName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: FruitColors.primaryGreen)
              ),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: user.roles.map((role) => _buildRoleBadge(role)).toList()
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        // Form thông tin bên phải
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: _boxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Thông tin định danh",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: FruitColors.accentGreen)),
                    if (!isEditing)
                      TextButton.icon(
                        onPressed: () => setState(() => isEditing = true),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Chỉnh sửa"),
                        style: TextButton.styleFrom(foregroundColor: FruitColors.accentGreen),
                      )
                  ],
                ),
                const Divider(height: 48, thickness: 1),

                _infoRow("Họ và tên", user.fullName, controller: _nameController, icon: Icons.person_outline),
                _infoRow("Địa chỉ Email", user.email, icon: Icons.email_outlined, canEdit: false),
                _infoRow("Số điện thoại", user.phone ?? "Chưa cập nhật",
                    controller: _phoneController, icon: Icons.phone_android, isNumberOnly: true, maxLength: 10),
                _infoRow("Tuổi", user.age?.toString() ?? "Chưa rõ",
                    controller: _ageController, icon: Icons.cake_outlined, isNumberOnly: true),
                _infoRow("Ngày gia nhập", DateFormat('dd/MM/yyyy').format(user.createdAt),
                    icon: Icons.calendar_today_outlined, canEdit: false),

                if (isEditing) ...[
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleUpdate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FruitColors.accentGreen,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Xác nhận lưu thay đổi",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => setState(() => isEditing = false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- REUSABLE INFO ROW ---
  Widget _infoRow(String label, String value, {
    IconData? icon,
    TextEditingController? controller,
    bool canEdit = true,
    bool isNumberOnly = false,
    int? maxLength
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: FruitColors.background, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: FruitColors.primaryGreen.withOpacity(0.6)),
          ),
          const SizedBox(width: 20),
          SizedBox(width: 180, child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 15))),
          Expanded(
            child: (isEditing && canEdit)
                ? TextFormField(
              controller: controller,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              keyboardType: isNumberOnly ? TextInputType.number : TextInputType.text,
              maxLength: maxLength,
              inputFormatters: [
                if (isNumberOnly) FilteringTextInputFormatter.digitsOnly,
                if (maxLength != null) LengthLimitingTextInputFormatter(maxLength)
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                counterText: "",
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: FruitColors.softGreen)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: FruitColors.accentGreen)),
              ),
            )
                : Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: FruitColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  // --- ORDER HISTORY PREVIEW ---
  Widget _buildOrderHistory() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(40),
    decoration: _boxDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Giao dịch gần đây",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: FruitColors.primaryGreen)),
            TextButton(
                onPressed: () {},
                child: const Text("Xem tất cả đơn hàng →", style: TextStyle(color: FruitColors.accentGreen))
            )
          ],
        ),
        const SizedBox(height: 32),
        _mockOrderItem("ORD-9921", "28/03/2026", "Đang giao hàng", Colors.orange, "850.000đ"),
        const Divider(height: 48, thickness: 1),
        _mockOrderItem("ORD-8812", "15/03/2026", "Giao hàng thành công", Colors.green, "1.200.000đ"),
      ],
    ),
  );

  Widget _mockOrderItem(String id, String date, String status, Color color, String amount) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(Icons.shopping_bag_outlined, color: color, size: 24),
      ),
      const SizedBox(width: 24),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: FruitColors.primaryGreen)),
          const SizedBox(height: 4),
          Text(status, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(width: 24),
      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[300]),
    ],
  );

  // --- UTILS & DECORATION ---
  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: FruitColors.softGreen.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))
    ],
  );

  Widget _buildRoleBadge(String roleName) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
        color: FruitColors.softGreen.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: FruitColors.softGreen)
    ),
    child: Text(
        roleName.replaceAll("ROLE_", ""),
        style: const TextStyle(fontSize: 11, color: FruitColors.accentGreen, fontWeight: FontWeight.bold)
    ),
  );

  Widget _buildErrorState(String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        Text("Không thể kết nối đến máy chủ", style: TextStyle(fontSize: 18, color: Colors.grey[800], fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(error, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _loadProfile, child: const Text("Thử tải lại trang")),
      ],
    ),
  );
}