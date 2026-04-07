import 'package:flutter/material.dart';

import '../../data/datasource/auth_remote_data_source.dart';
// import 'path_to_your_datasource/auth_remote_data_source.dart';

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

  final Color primaryColor = const Color(0xFF1E824C);
  final Color brownColor = const Color(0xFF6E4A3A);
  final Color accentColor = const Color(0xFFE05633);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Khôi phục mật khẩu"),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Ô nhập Email
                TextFormField(
                  controller: _emailController,
                  // QUAN TRỌNG: Khóa ô nhập nếu đã gửi mã thành công
                  readOnly: _isCodeSent,
                  style: TextStyle(color: _isCodeSent ? Colors.grey : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Nhập Email đăng ký",
                    border: const OutlineInputBorder(),
                    // Thêm icon thông báo khi đã khóa
                    suffixIcon: _isCodeSent ? const Icon(Icons.lock, color: Colors.grey) : null,
                    filled: _isCodeSent,
                    fillColor: _isCodeSent ? Colors.grey.shade100 : Colors.white,
                  ),
                  validator: (val) => val!.isEmpty ? "Vui lòng nhập email" : null,
                ),
                const SizedBox(height: 20),

                if (!_isCodeSent) ...[
                  // NÚT 1: GỬI MÃ
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: brownColor),
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            // Gọi API từ Server Spring Boot của Hùng
                            final msg = await _dataSource.forgotPassword(_emailController.text);

                            setState(() => _isCodeSent = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg), backgroundColor: primaryColor)
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: accentColor)
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("GỬI MÃ XÁC NHẬN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ] else ...[
                  // HIỆN KHI ĐÃ GỬI MÃ XONG
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(labelText: "Nhập mã OTP từ Email", border: OutlineInputBorder()),
                    validator: (val) => val!.isEmpty ? "Vui lòng nhập mã OTP" : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Mật khẩu mới", border: OutlineInputBorder()),
                    validator: (val) => val!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
                  ),
                  const SizedBox(height: 24),

                  // NÚT 2: ĐỔI MẬT KHẨU
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                      onPressed: _isLoading ? null : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          try {
                            final msg = await _dataSource.resetPassword(
                              _emailController.text,
                              _codeController.text,
                              _newPasswordController.text,
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(msg), backgroundColor: Colors.green)
                            );
                            // Thành công thì quay về trang Login sau 2 giây
                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pop(context);
                            });
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: accentColor)
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        }
                      },
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("XÁC NHẬN ĐỔI MẬT KHẨU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Nút bấm lại nếu nhập sai email
                  TextButton(
                    onPressed: () => setState(() => _isCodeSent = false),
                    child: Text("Nhập lại Email khác", style: TextStyle(color: brownColor)),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}