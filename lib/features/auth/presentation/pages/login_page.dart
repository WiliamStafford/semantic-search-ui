import 'package:flutter/material.dart';
import '../../../../views/screens/FruitProfileScreen.dart';
import '../../data/datasource/auth_remote_data_source.dart';
import 'ForgotPasswordPage.dart';
import 'register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final Color primaryColor = const Color(0xFF1E824C);
  final Color brownColor = const Color(0xFF6E4A3A);
  final Color accentColor = const Color(0xFFE05633);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.shopping_basket_rounded, size: 70, color: primaryColor),
                ),
                const SizedBox(height: 16),
                Text("CỬA HÀNG HOA QUẢ TƯƠI", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: brownColor)),
                Text("Trái cây sạch cho sức khỏe của bạn", style: TextStyle(color: brownColor.withOpacity(0.8))),
                const SizedBox(height: 48),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ Email',
                    labelStyle: TextStyle(color: brownColor),
                    prefixIcon: Icon(Icons.mail_outline_rounded, color: primaryColor),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val!.isEmpty ? "Vui lòng nhập email" : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    labelStyle: TextStyle(color: brownColor),
                    prefixIcon: Icon(Icons.vpn_key_outlined, color: primaryColor),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 2)),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) => val!.length < 6 ? "Mật khẩu tối thiểu 6 ký tự" : null,
                ),
                const SizedBox(height: 8), // Khoảng cách nhỏ với ô Password

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: Text(
                      "Quên mật khẩu?",
                      style: TextStyle(
                        color: brownColor,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          final dataSource = AuthRemoteDataSource();
                          final result = await dataSource.login(
                              _emailController.text,
                              _passwordController.text
                          );

                          if (result['accessToken'] != null) {
                            final SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setString('accessToken', result['accessToken']);

                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FruitProfileScreen(accessToken: result['accessToken']),
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(e.toString().replaceAll("Exception: ", "")),
                                backgroundColor: const Color(0xFFE05633)
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('ĐĂNG NHẬP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage()));
                  },
                  child: Text('Chưa có tài khoản? Đăng ký ngay', style: TextStyle(color: accentColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}