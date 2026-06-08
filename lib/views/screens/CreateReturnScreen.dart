import 'dart:io' show File; // Import an toàn phục vụ môi trường Mobile/Windows
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; // Kiếm tra nền tảng biên dịch Web hay Native

import '../theme/fruit_colors.dart';

class CreateReturnScreen extends StatefulWidget {
  final int orderItemId;
  final String accessToken;
  final int userId;

  const CreateReturnScreen({
    super.key,
    required this.orderItemId,
    required this.accessToken,
    required this.userId,
  });

  @override
  State<CreateReturnScreen> createState() => _CreateReturnScreenState();
}

class _CreateReturnScreenState extends State<CreateReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers quản lý dữ liệu nhập vào
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNumController = TextEditingController();
  final TextEditingController _bankAccountNameController = TextEditingController();
  final TextEditingController _paypalEmailController = TextEditingController();

  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  String _selectedRefundMethod = 'BANK_TRANSFER';
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    _bankNameController.dispose();
    _bankAccountNumController.dispose();
    _bankAccountNameController.dispose();
    _paypalEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 8) {
      _showSnackBar("Bạn chỉ được phép chọn tối đa 8 ảnh minh chứng!", Colors.orange);
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70, // Nén nhẹ chất lượng ảnh để giảm băng thông upload
        maxWidth: 1440,
      );

      if (images.isNotEmpty) {
        setState(() {
          // Kiểm tra nếu tổng số ảnh sau khi thêm vượt quá 8
          if (_selectedImages.length + images.length > 8) {
            _showSnackBar("Tổng số ảnh vượt quá giới hạn! Hệ thống tự động lấy 8 ảnh đầu tiên.", Colors.orange);
            int slotsLeft = 8 - _selectedImages.length;
            for (var i = 0; i < slotsLeft; i++) {
              _selectedImages.add(images[i]);
            }
          } else {
            _selectedImages.addAll(images);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Lỗi khi chọn hình ảnh: $e", Colors.red);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReturnRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      _showSnackBar("Vui lòng tải lên ít nhất 1 hình ảnh minh chứng!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload ảnh
      var uploadUri = Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/returns/upload-evidence');
      var uploadRequest = http.MultipartRequest('POST', uploadUri);
      uploadRequest.headers.addAll({
        'Authorization': 'Bearer ${widget.accessToken}',
        'ngrok-skip-browser-warning': 'any',
      });

      for (XFile imageFile in _selectedImages) {
        if (kIsWeb) {
          uploadRequest.files.add(http.MultipartFile.fromBytes('files', await imageFile.readAsBytes(), filename: imageFile.name));
        } else {
          uploadRequest.files.add(await http.MultipartFile.fromPath('files', imageFile.path));
        }
      }

      var streamedResponse = await uploadRequest.send();
      var uploadResponse = await http.Response.fromStream(streamedResponse);

      if (uploadResponse.statusCode != 200) {
        throw Exception("Tải ảnh thất bại: ${uploadResponse.statusCode}");
      }

      var uploadData = jsonDecode(utf8.decode(uploadResponse.bodyBytes));
      String evidenceUrlsString = (uploadData['urls'] as List).join(",");

      var requestUri = Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/returns/request');
      var response = await http.post(
        requestUri,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'any',
        },
        body: jsonEncode({
          'orderItemId': widget.orderItemId,
          'reason': _reasonController.text.trim(),
          'evidence': evidenceUrlsString,
          'refundMethod': _selectedRefundMethod,
          'bankName': _selectedRefundMethod == 'BANK_TRANSFER' ? _bankNameController.text.trim() : null,
          'bankAccountNumber': _selectedRefundMethod == 'BANK_TRANSFER' ? _bankAccountNumController.text.trim() : null,
          'bankAccountName': _selectedRefundMethod == 'BANK_TRANSFER' ? _bankAccountNameController.text.trim().toUpperCase() : null,
          'paypalEmail': _selectedRefundMethod == 'PAYPAL' ? _paypalEmailController.text.trim() : null,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar("Gửi khiếu nại thành công!", Colors.green);
        if (mounted) Navigator.pop(context, true);
      } else {
        String errorMsg = "Lỗi xử lý yêu cầu.";
        try {
          debugPrint("Lỗi từ backend: ${response.body}");

          var errorData = jsonDecode(utf8.decode(response.bodyBytes));

          if (errorData is Map && errorData.containsKey('message')) {
            errorMsg = errorData['message'];
          } else {
            errorMsg = errorData.toString();
          }
        } catch (e) {
          errorMsg = "Lỗi hệ thống (${response.statusCode})";
        }
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      debugPrint("Lỗi chi tiết: $e");
      _showSnackBar("Kết nối thất bại: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      appBar: AppBar(
        title: const Text("Tạo Đơn Khiếu Nại / Đổi Trả", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: FruitColors.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thẻ thông tin mã món hàng cần khiếu nại
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Text(" Mã dòng sản phẩm khiếu nại: #ITEM-${widget.orderItemId}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
              ),
              const SizedBox(height: 20),

              const Text("Lý do khiếu nại hoàn tiền:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                validator: (value) => (value == null || value.trim().isEmpty) ? "Vui lòng không bỏ trống lý do khiếu nại!" : null,
                decoration: InputDecoration(
                  hintText: "Mô tả chi tiết tình trạng trái cây khi nhận hàng (ví dụ: bị dập nát, thối hỏng, sai mẫu mã...)",
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  fillColor: Colors.white, filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Hình ảnh minh chứng (${_selectedImages.length}/8):", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
                  TextButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined, color: FruitColors.accentGreen, size: 20),
                    label: const Text("Chọn ảnh", style: TextStyle(color: FruitColors.accentGreen, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 6),

              _selectedImages.isEmpty
                  ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  children: [
                    Icon(Icons.camera_enhance_outlined, size: 36, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Yêu cầu tối thiểu 1 hình ảnh rõ nét tình trạng hàng", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
                  : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                ),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.network(_selectedImages[index].path, fit: BoxFit.cover) // Dành cho Trình duyệt Web
                              : Image.file(File(_selectedImages[index].path), fit: BoxFit.cover), // Dành cho Windows/Mobile
                        ),
                      ),
                      Positioned(
                        top: 2, right: 2,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 12, color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              const Text("Phương thức thanh khoản hoàn tiền:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRefundMethod,
                decoration: InputDecoration(
                  fillColor: Colors.white, filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'BANK_TRANSFER', child: Text('Chuyển khoản Ngân hàng (Nội địa)')),
                  DropdownMenuItem(value: 'PAYPAL', child: Text('Ví quốc tế (PayPal)')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRefundMethod = value!;

                    if (_selectedRefundMethod == 'BANK_TRANSFER') {
                      _paypalEmailController.clear();
                    } else if (_selectedRefundMethod == 'PAYPAL') {
                      _bankNameController.clear();
                      _bankAccountNumController.clear();
                      _bankAccountNameController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              if (_selectedRefundMethod == 'BANK_TRANSFER') ...[
                _buildAnimatedFormContainer(
                  key: const ValueKey('FORM_BANK'),
                  children: [
                    _buildInputField(_bankNameController, "Tên Ngân hàng (Ví dụ: Vietcombank, MB, Techcombank...)"),
                    const SizedBox(height: 12),
                    _buildInputField(_bankAccountNumController, "Số tài khoản nhận tiền", isNumber: true),
                    const SizedBox(height: 12),
                    _buildInputField(_bankAccountNameController, "Tên chủ tài khoản (Viết hoa không dấu)"),
                  ],
                ),
              ] else if (_selectedRefundMethod == 'PAYPAL') ...[
                _buildAnimatedFormContainer(
                  key: const ValueKey('FORM_PAYPAL'),
                  children: [
                    _buildInputField(_paypalEmailController, "Địa chỉ Email liên kết ví PayPal", isEmail: true),
                  ],
                ),
              ],
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitReturnRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FruitColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("XÁC NHẬN GỬI YÊU CẦU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFormContainer({Key? key, required List<Widget> children}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.1)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, {bool isNumber = false, bool isEmail = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
      validator: (value) {
        if (value == null || value.trim().isEmpty) return "Trường dữ liệu này bắt buộc điền!";
        if (isEmail && !RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
          return "Định dạng Email không hợp lệ!";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        fillColor: Colors.white, filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}