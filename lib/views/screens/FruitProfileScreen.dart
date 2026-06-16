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
  String _sellerStatus = 'NOT_REGISTERED';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSellerStatus();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    _houseController.dispose();
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

      _provinceController.text = user.province ?? "";
      _districtController.text = user.district ?? "";
      _wardController.text = user.ward ?? "";
      _streetController.text = user.street ?? "";
      _houseController.text = user.houseNumber ?? "";
    }).catchError((error) => debugPrint("Lỗi tải profile: $error"));
  }

  Future<void> _loadSellerStatus() async {
    try {
      final status = await UserRemoteDataSource().getSellerRegistrationStatus(
        widget.accessToken,
      );
      if (mounted) setState(() => _sellerStatus = status);
    } catch (e) {
      debugPrint("Lỗi: $e");
    }
  }

  void _showRegistrationForm() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Đăng ký trở thành Seller"),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "⚠️ Lưu ý: Các sản phẩm đăng bán phải là nông sản. Nếu vi phạm, tài khoản của bạn sẽ bị ban vĩnh viễn.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Tên gian hàng",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: "Địa chỉ kinh doanh",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: "Mô tả cửa hàng",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty ||
                          addressController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Vui lòng điền tên gian hàng và địa chỉ!",
                            ),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      try {
                        final request = {
                          "shopName": nameController.text.trim(),
                          "address": addressController.text.trim(),
                          "description": descController.text.trim(),
                        };

                        await UserRemoteDataSource().registerSeller(
                          widget.accessToken,
                          request,
                        );

                        if (mounted) {
                          setDialogState(() => isSubmitting = false);
                          Navigator.pop(context);
                          await _loadSellerStatus();
                          setState(() {});

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Gửi đơn thành công!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isSubmitting = false);
                        if (mounted)
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: FruitColors.accentGreen,
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Gửi yêu cầu"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSellerAction() {
    switch (_sellerStatus) {
      case 'PENDING':
        return OutlinedButton.icon(
          onPressed: () =>
              _showStatusMessage("Đơn đăng ký của bạn đang được xử lý."),
          icon: const Icon(Icons.access_time, color: Colors.orange),
          label: const Text(
            "Trạng thái đơn đăng ký",
            style: TextStyle(color: Colors.orange),
          ),
        );
      case 'ACTIVE':
        return OutlinedButton.icon(
          onPressed: () => _showStatusMessage(
            "Chúc mừng, đơn đăng ký trở thành seller đã được duyệt thành công!",
          ),
          icon: const Icon(Icons.check_circle, color: Colors.green),
          label: const Text(
            "Trạng thái đơn đăng ký",
            style: TextStyle(color: Colors.green),
          ),
        );
      case 'REJECTED':
        return OutlinedButton.icon(
          onPressed: () => _showStatusMessage(
            "Đơn bị từ chối. Vui lòng liên hệ 0944982985 hoặc qua email levuhung678@gmail.com.",
          ),
          icon: const Icon(Icons.error, color: Colors.red),
          label: const Text(
            "Trạng thái đơn đăng ký",
            style: TextStyle(color: Colors.red),
          ),
        );
      default:
        return ElevatedButton.icon(
          onPressed: _showRegistrationForm,
          icon: const Icon(Icons.storefront),
          label: const Text("Đăng ký trở thành Seller"),
          style: ElevatedButton.styleFrom(
            backgroundColor: FruitColors.accentGreen,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  void _showStatusMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Trạng thái đăng ký"),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUpdate() async {
    try {
      final updateData = {
        "fullName": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "age": int.tryParse(_ageController.text.trim()),
        "province": _provinceController.text.trim(),
        "district": _districtController.text.trim(),
        "ward": _wardController.text.trim(),
        "street": _streetController.text.trim(),
        "houseNumber": _houseController.text.trim(),
        "avatar": null,
      };
      await UserRemoteDataSource().updateProfile(
        widget.accessToken,
        updateData,
      );
      setState(() {
        isEditing = false;
        _loadProfile();
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật thành công!"),
            backgroundColor: Colors.green,
          ),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<UserModel>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !isEditing) {
            return const Center(
              child: CircularProgressIndicator(color: FruitColors.accentGreen),
            );
          } else if (snapshot.hasError)
            return _buildErrorState(snapshot.error.toString());
          else if (!snapshot.hasData)
            return const Center(child: Text("Không tìm thấy dữ liệu"));

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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Hồ sơ cá nhân",
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: FruitColors.primaryGreen,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        "Quản lý thông tin tài khoản và bảo mật của bạn",
        style: TextStyle(color: Colors.grey[600], fontSize: 16),
      ),
    ],
  );

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
              CircleAvatar(
                radius: 60,
                backgroundColor: FruitColors.accentGreen.withOpacity(0.1),
                backgroundImage: user.avatar != null
                    ? NetworkImage(user.avatar!)
                    : null,
                child: user.avatar == null
                    ? Text(
                        user.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          color: FruitColors.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 24),
              Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: FruitColors.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: user.roles
                    .map((role) => _buildRoleBadge(role))
                    .toList(),
              ),
              const SizedBox(height: 20),
              _buildSellerAction(),
            ],
          ),
        ),
        const SizedBox(width: 40),
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
                    const Text(
                      "Thông tin định danh",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: FruitColors.accentGreen,
                      ),
                    ),
                    if (!isEditing)
                      TextButton.icon(
                        onPressed: () => setState(() => isEditing = true),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text("Chỉnh sửa"),
                        style: TextButton.styleFrom(
                          foregroundColor: FruitColors.accentGreen,
                        ),
                      ),
                  ],
                ),
                const Divider(height: 48, thickness: 1),
                _infoRow(
                  "Họ và tên",
                  user.fullName,
                  controller: _nameController,
                  icon: Icons.person_outline,
                ),
                _infoRow(
                  "Địa chỉ Email",
                  user.email,
                  icon: Icons.email_outlined,
                  canEdit: false,
                ),
                _infoRow(
                  "Số điện thoại",
                  user.phone ?? "Chưa cập nhật",
                  controller: _phoneController,
                  icon: Icons.phone_android,
                  isNumberOnly: true,
                  maxLength: 10,
                ),
                _infoRow(
                  "Tuổi",
                  user.age?.toString() ?? "Chưa rõ",
                  controller: _ageController,
                  icon: Icons.cake_outlined,
                  isNumberOnly: true,
                ),
                _infoRow(
                  "Tỉnh/Thành",
                  user.province ?? "",
                  controller: _provinceController,
                  icon: Icons.map_outlined,
                ),
                // _infoRow(
                //   "Quận/Huyện",
                //   user.district ?? "",
                //   controller: _districtController,
                //   icon: Icons.location_city_outlined,
                // ),
                _infoRow(
                  "Phường/Xã",
                  user.ward ?? "",
                  controller: _wardController,
                  icon: Icons.home_work_outlined,
                ),
                _infoRow(
                  "Đường",
                  user.street ?? "",
                  controller: _streetController,
                  icon: Icons.signpost_outlined,
                ),
                _infoRow(
                  "Số nhà",
                  user.houseNumber ?? "",
                  controller: _houseController,
                  icon: Icons.home_outlined,
                ),
                _infoRow(
                  "Ngày gia nhập",
                  DateFormat('dd/MM/yyyy').format(user.createdAt ?? DateTime.now()),
                  icon: Icons.calendar_today_outlined,
                  canEdit: false,
                ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Lưu thay đổi",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => setState(() => isEditing = false),
                        child: const Text("Hủy"),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    IconData? icon,
    TextEditingController? controller,
    bool canEdit = true,
    bool isNumberOnly = false,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FruitColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: FruitColors.primaryGreen.withOpacity(0.6),
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ),
        Expanded(
          child: (isEditing && canEdit)
              ? TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: FruitColors.primaryGreen,
                  ),
                ),
        ),
      ],
    ),
  );

  BoxDecoration _boxDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: FruitColors.softGreen.withOpacity(0.3)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  Widget _buildRoleBadge(String roleName) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: FruitColors.softGreen.withOpacity(0.2),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: FruitColors.softGreen),
    ),
    child: Text(
      roleName.replaceAll("ROLE_", ""),
      style: const TextStyle(
        fontSize: 11,
        color: FruitColors.accentGreen,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _buildErrorState(String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.cloud_off, color: Colors.red, size: 80),
        const SizedBox(height: 24),
        Text(
          "Không kết nối server",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ElevatedButton(onPressed: _loadProfile, child: const Text("Tải lại")),
      ],
    ),
  );
}
