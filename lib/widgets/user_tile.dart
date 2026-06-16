// import 'package:flutter/material.dart';
// import '../data/models/user_model.dart';
//
// class UserTile extends StatefulWidget {
//   final UserModel user;
//   final Function(int, String, String, String, String, String, String, String) onUpdate;
//   final Function(int) onBlock;
//   const UserTile({super.key, required this.user, required this.onUpdate});
//
//   @override
//   State<UserTile> createState() => _UserTileState();
// }
//
// class _UserTileState extends State<UserTile> {
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;
//   late TextEditingController _provinceController;
//   late TextEditingController _districtController;
//   late TextEditingController _wardController;
//   late TextEditingController _streetController;
//   late TextEditingController _houseController;
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.user.fullName);
//     _phoneController = TextEditingController(text: widget.user.phone ?? "");
//     _provinceController = TextEditingController(text: widget.user.province ?? "");
//     _districtController = TextEditingController(text: widget.user.district ?? "");
//     _wardController = TextEditingController(text: widget.user.ward ?? "");
//     _streetController = TextEditingController(text: widget.user.street ?? "");
//     _houseController = TextEditingController(text: widget.user.houseNumber ?? "");
//   }
//
//   @override
//   void dispose() {
//     // QUAN TRỌNG: Giải phóng bộ nhớ khi widget bị hủy
//     _nameController.dispose();
//     _phoneController.dispose();
//     _provinceController.dispose();
//     _districtController.dispose();
//     _wardController.dispose();
//     _streetController.dispose();
//     _houseController.dispose();
//     super.dispose();
//   }
//
//   // Phương thức hỗ trợ tạo TextField đồng bộ
//   Widget _buildTextField(TextEditingController controller, String label) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12.0),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//       child: ExpansionTile(
//         leading: CircleAvatar(child: Text(widget.user.fullName[0].toUpperCase())),
//         title: Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(widget.user.email),
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 _buildTextField(_nameController, "Họ tên"),
//                 _buildTextField(_phoneController, "Điện thoại"),
//                 const Divider(), // Ngăn cách nhóm thông tin chung và địa chỉ
//                 _buildTextField(_provinceController, "Tỉnh/Thành"),
//                 _buildTextField(_districtController, "Quận/Huyện"),
//                 _buildTextField(_wardController, "Phường/Xã"),
//                 _buildTextField(_streetController, "Đường"),
//                 _buildTextField(_houseController, "Số nhà"),
//                 const SizedBox(height: 10),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () => widget.onUpdate(
//                       widget.user.id,
//                       _nameController.text,
//                       _phoneController.text,
//                       _provinceController.text,
//                       _districtController.text,
//                       _wardController.text,
//                       _streetController.text,
//                       _houseController.text,
//                     ),
//                     child: const Text("Cập nhật thông tin"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../data/models/user_model.dart';

class UserTile extends StatefulWidget {
  final UserModel user;
  final Function(int, String, String, String, String, String, String, String) onUpdate;
  final Function(int) onBlock; // Đã thêm tham số onBlock

  const UserTile({
    super.key,
    required this.user,
    required this.onUpdate,
    required this.onBlock, // Đã thêm vào constructor
  });

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _provinceController;
  late TextEditingController _districtController;
  late TextEditingController _wardController;
  late TextEditingController _streetController;
  late TextEditingController _houseController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone ?? "");
    _provinceController = TextEditingController(text: widget.user.province ?? "");
    _districtController = TextEditingController(text: widget.user.district ?? "");
    _wardController = TextEditingController(text: widget.user.ward ?? "");
    _streetController = TextEditingController(text: widget.user.street ?? "");
    _houseController = TextEditingController(text: widget.user.houseNumber ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    _houseController.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: widget.user.enabled ? Colors.blue.shade100 : Colors.red.shade100,
          child: Text(widget.user.fullName[0].toUpperCase()),
        ),
        title: Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(widget.user.email),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTextField(_nameController, "Họ tên"),
                _buildTextField(_phoneController, "Điện thoại"),
                const Divider(),
                _buildTextField(_provinceController, "Tỉnh/Thành"),
                _buildTextField(_districtController, "Quận/Huyện"),
                _buildTextField(_wardController, "Phường/Xã"),
                _buildTextField(_streetController, "Đường"),
                _buildTextField(_houseController, "Số nhà"),
                const SizedBox(height: 10),

                // Nút cập nhật
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => widget.onUpdate(
                      widget.user.id,
                      _nameController.text,
                      _phoneController.text,
                      _provinceController.text,
                      _districtController.text,
                      _wardController.text,
                      _streetController.text,
                      _houseController.text,
                    ),
                    child: const Text("Cập nhật thông tin"),
                  ),
                ),
                const SizedBox(height: 10),

                // Nút khóa/mở khóa
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.user.enabled ? Colors.red.shade50 : Colors.green.shade50,
                      foregroundColor: widget.user.enabled ? Colors.red : Colors.green,
                    ),
                    onPressed: () => widget.onBlock(widget.user.id),
                    child: Text(widget.user.enabled ? "Khóa tài khoản" : "Mở khóa tài khoản"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}