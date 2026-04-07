import 'package:flutter/material.dart';

import '../../data/datasource/auth_remote_data_source.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color primaryColor = const Color(0xFF1E824C);
  final Color brownColor = const Color(0xFF6E4A3A);
  final Color accentColor = const Color(0xFFE05633);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent, iconTheme: IconThemeData(color: brownColor)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tạo tài khoản", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: brownColor)),
              const SizedBox(height: 8),
              Text("Tham gia cộng đồng trái cây sạch", style: TextStyle(color: brownColor.withOpacity(0.8), fontSize: 16)),
              const SizedBox(height: 48),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Họ và tên',
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập tên" : null,
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ Email',
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? "Vui lòng nhập email" : null,
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
              ),
              const SizedBox(height: 36),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      try {
                        final dataSource = AuthRemoteDataSource();

                        final result = await dataSource.register(
                          _nameController.text,  //  fullName
                          _emailController.text, //  email
                          _passController.text,  //  password
                        );

                        if (result['accessToken'] != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? "Đăng ký thành công!"),
                              backgroundColor: primaryColor,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        // 4. Xử lý lỗi (Ví dụ: Email đã tồn tại)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll("Exception: ", "")),
                            backgroundColor: accentColor,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}