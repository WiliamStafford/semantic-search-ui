// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// import '../../../../views/screens/FruitHomeScreen.dart';
// import '../../data/datasource/auth_remote_data_source.dart';
// import 'ForgotPasswordPage.dart';
// import 'register_page.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   bool _rememberMe = false;
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//
//   // Palette màu hiện đại cho FruitFresh
//   final Color primaryPurple = const Color(0xFF6C28FE);
//   final Color greyBg = const Color(0xFFF8F9FA);
//
//   @override
//   Widget build(BuildContext context) {
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final bool isMobile = screenWidth < 850;
//
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Row(
//         children: [
//           // --- CỘT TRÁI: HÌNH ẢNH (ẨN TRÊN MOBILE) ---
//           if (!isMobile)
//             Expanded(
//               flex: 1,
//               child: Stack(
//                 children: [
//                   Container(
//                     decoration: const BoxDecoration(
//                       image: DecorationImage(
//                         // Sử dụng ảnh 4K để không bị mờ khi demo
//                         image: NetworkImage('https://images.unsplash.com/photo-1610832958506-aa56368176cf?q=80&w=2000&auto=format&fit=crop'),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
//                       ),
//                     ),
//                   ),
//                   const Positioned(
//                     bottom: 60,
//                     left: 50,
//                     right: 50,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           "FruitFresh",
//                           style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
//                         ),
//                         SizedBox(height: 10),
//                         Text(
//                           "Trái cây tươi ngon từ trang trại,\ngiao tận cửa nhà bạn mỗi ngày.",
//                           style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//           // --- CỘT PHẢI: FORM ĐĂNG NHẬP ---
//           Expanded(
//             flex: 1,
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
//                 child: Container(
//                   constraints: const BoxConstraints(maxWidth: 420),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text("Chào mừng trở lại!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
//                         const SizedBox(height: 8),
//                         const Text("Đăng nhập để tiếp tục trải nghiệm thực phẩm sạch", style: TextStyle(color: Colors.grey, fontSize: 14)),
//                         const SizedBox(height: 40),
//
//                         // Input Email
//                         _buildLabel("ĐỊA CHỈ EMAIL"),
//                         const SizedBox(height: 8),
//                         _buildTextField(
//                           controller: _emailController,
//                           hint: "vidu@email.com",
//                           prefixIcon: Icons.email_outlined,
//                           validator: (v) => (v == null || !v.contains('@')) ? "Email không hợp lệ" : null,
//                         ),
//                         const SizedBox(height: 20),
//
//                         // Input Mật khẩu
//                         _buildLabel("MẬT KHẨU"),
//                         const SizedBox(height: 8),
//                         _buildTextField(
//                           controller: _passwordController,
//                           hint: "••••••••",
//                           isPassword: true,
//                           prefixIcon: Icons.lock_outline,
//                           suffixIcon: IconButton(
//                             icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
//                             onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                           ),
//                           validator: (v) => (v == null || v.length < 6) ? "Mật khẩu tối thiểu 6 ký tự" : null,
//                         ),
//
//                         const SizedBox(height: 10),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Row(
//                               children: [
//                                 Checkbox(
//                                   value: _rememberMe,
//                                   activeColor: primaryPurple,
//                                   onChanged: (v) => setState(() => _rememberMe = v!),
//                                 ),
//                                 const Text("Ghi nhớ", style: TextStyle(fontSize: 13)),
//                               ],
//                             ),
//                             TextButton(
//                               onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage())),
//                               child: Text("Quên mật khẩu?", style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13)),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 30),
//
//                         // Nút Đăng nhập
//                         _buildLoginButton(),
//
//                         const SizedBox(height: 32),
//                         const Center(child: Text("HOẶC TIẾP TỤC VỚI", style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2))),
//                         const SizedBox(height: 20),
//
//                         // Nút Google (Fix lỗi SVG và Overflow)
//                         _buildGoogleButton(),
//
//                         const SizedBox(height: 40),
//                         Center(
//                           child: Wrap(
//                             alignment: WrapAlignment.center,
//                             children: [
//                               const Text("Bạn mới biết đến FruitFresh? "),
//                               GestureDetector(
//                                 onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
//                                 child: Text("Tạo tài khoản", style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --- WIDGETS PHỤ TRỢ ---
//
//   Widget _buildLabel(String text) {
//     return Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8));
//   }
//
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData prefixIcon,
//     bool isPassword = false,
//     Widget? suffixIcon,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword && _obscurePassword,
//       validator: validator,
//       decoration: InputDecoration(
//         hintText: hint,
//         prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey),
//         suffixIcon: suffixIcon,
//         filled: true,
//         fillColor: greyBg,
//         contentPadding: const EdgeInsets.symmetric(vertical: 18),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
//         focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryPurple.withOpacity(0.5))),
//       ),
//     );
//   }
//
//   Widget _buildLoginButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryPurple,
//           elevation: 0,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         onPressed: _isLoading ? null : _handleLogin,
//         child: _isLoading
//             ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//             : const Text('Đăng Nhập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
//       ),
//     );
//   }
//
//   Widget _buildGoogleButton() {
//     return SizedBox(
//       width: double.infinity,
//       height: 56,
//       child: OutlinedButton(
//         style: OutlinedButton.styleFrom(
//           side: BorderSide(color: Colors.grey.shade300),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         onPressed: () {}, // Logic Google Login xử lý sau
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             SvgPicture.network('https://www.svgrepo.com/show/475656/google_color.svg', width: 20),
//             const SizedBox(width: 12),
//             const Text("Tiếp tục với Google", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // --- LOGIC XỬ LÝ ĐĂNG NHẬP ---
//   Future<void> _handleLogin() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
//       try {
//         final dataSource = AuthRemoteDataSource();
//         final result = await dataSource.login(
//             _emailController.text.trim(),
//             _passwordController.text
//         );
//
//         if (result['accessToken'] != null) {
//           final SharedPreferences prefs = await SharedPreferences.getInstance();
//           await prefs.setString('accessToken', result['accessToken']);
//
//           if (mounted) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => FruitHomeScreen(accessToken: result['accessToken'])),
//             );
//           }
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//                 content: Text(e.toString().replaceAll("Exception: ", "")),
//                 backgroundColor: Colors.redAccent
//             ),
//           );
//         }
//       } finally {
//         if (mounted) setState(() => _isLoading = false);
//       }
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../views/screens/MainLayoutScreen.dart';
import '../../data/datasource/auth_remote_data_source.dart';
import 'ForgotPasswordPage.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryPurple = const Color(0xFF6C28FE);
  final Color greyBg = const Color(0xFFF8F9FA);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // --- CỘT TRÁI ---
          if (!isMobile)
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1610832958506-aa56368176cf?q=80&w=2000&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 60, left: 50, right: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("FruitFresh", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text("Trái cây tươi ngon từ trang trại,\ngiao tận cửa nhà bạn mỗi ngày.", style: TextStyle(color: Colors.white70, fontSize: 18, height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // --- CỘT PHẢI: FORM ĐĂNG NHẬP ---
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Chào mừng trở lại!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 40),

                        _buildLabel("ĐỊA CHỈ EMAIL"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: "vidu@email.com",
                          prefixIcon: Icons.email_outlined,
                          validator: (v) => (v == null || !v.contains('@')) ? "Email không hợp lệ" : null,
                        ),
                        const SizedBox(height: 20),

                        _buildLabel("MẬT KHẨU"),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: "••••••••",
                          isPassword: true,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          validator: (v) => (v == null || v.length < 6) ? "Mật khẩu tối thiểu 6 ký tự" : null,
                        ),

                        const SizedBox(height: 30),
                        _buildLoginButton(),

                        const SizedBox(height: 40),
                        Center(
                          child: Wrap(
                            children: [
                              const Text("Bạn mới biết đến FruitFresh? "),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterPage())),
                                child: Text("Tạo tài khoản", style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  // --- LOGIC XỬ LÝ ĐĂNG NHẬP ---
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final dataSource = AuthRemoteDataSource();
        final result = await dataSource.login(
            _emailController.text.trim(),
            _passwordController.text
        );

        if (result['accessToken'] != null) {
          final String token = result['accessToken'];
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', token);

          if (mounted) {
            // 🌟 FIXED: Điều hướng về bộ khung MainLayoutScreen thay vì trang con
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainLayoutScreen(accessToken: token)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // Các widget _buildLabel, _buildTextField, _buildLoginButton giữ nguyên...
  Widget _buildLabel(String text) => Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.8));

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData prefixIcon, bool isPassword = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: greyBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        onPressed: _isLoading ? null : _handleLogin,
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng Nhập', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGoogleButton() => SizedBox(width: double.infinity, height: 56, child: OutlinedButton(onPressed: () {}, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [SvgPicture.network('https://www.svgrepo.com/show/475656/google_color.svg', width: 20), const SizedBox(width: 12), const Text("Tiếp tục với Google")]),));
}