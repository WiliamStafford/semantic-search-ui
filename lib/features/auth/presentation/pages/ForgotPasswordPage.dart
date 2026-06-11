import 'dart:ui';
import 'package:flutter/material.dart';
import '../../data/datasource/auth_remote_data_source.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _dataSource = AuthRemoteDataSource();

  bool _isCodeSent = false;
  bool _isLoading = false;

  final Color primaryColor = const Color(0xFF1E824C); // Xanh lá chủ đạo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Màu nền tổng thể nhạt
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_reset, size: 60, color: primaryColor),
                          const SizedBox(height: 16),
                          const Text("Khôi phục mật khẩu",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                          const SizedBox(height: 24),

                          // Trường Email
                          _buildTextField(_emailController, "Nhập Email đăng ký", Icons.email_outlined, _isCodeSent),

                          if (_isCodeSent) ...[
                            const SizedBox(height: 16),
                            _buildTextField(_codeController, "Nhập mã OTP từ Email", Icons.numbers, false),
                            const SizedBox(height: 16),
                            _buildTextField(_newPasswordController, "Mật khẩu mới", Icons.lock_outline, false, obscure: true),
                            const SizedBox(height: 24),
                            _buildButton("XÁC NHẬN ĐỔI MẬT KHẨU", _handleResetPassword),
                            TextButton(
                              onPressed: () => setState(() => _isCodeSent = false),
                              child: Text("Nhập lại Email khác", style: TextStyle(color: primaryColor)),
                            ),
                          ] else ...[
                            const SizedBox(height: 24),
                            _buildButton("GỬI MÃ XÁC NHẬN", _handleSendCode),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper cho TextField
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool readOnly, {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscure,
      validator: (val) => val!.isEmpty ? "Vui lòng không để trống" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
      ),
    );
  }

  // Helper cho Button
  Widget _buildButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isLoading ? null : onPressed,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Logic cũ của bạn
  Future<void> _handleSendCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final msg = await _dataSource.forgotPassword(_emailController.text);
        setState(() => _isCodeSent = true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: primaryColor));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final msg = await _dataSource.resetPassword(
            _emailController.text, _codeController.text, _newPasswordController.text);

        debugPrint("Server trả về sau khi đổi pass: $msg");

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

        // THAY VÌ POP, HÃY DÙNG LOGOUT ĐỂ XÓA HẾT TOKEN CŨ
        // await _dataSource.logout();

        Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
      } catch (e) {
        debugPrint("LỖI KHI RESET: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}