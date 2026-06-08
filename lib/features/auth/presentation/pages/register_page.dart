import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/datasource/auth_remote_data_source.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color primaryPurple = const Color(0xFF6C28FE);
  final Color greyBg = const Color(0xFFF8F9FA);

  // --- LOGIC XỬ LÝ ĐĂNG KÝ (Dựa trên bản ổn định của Hùng) ---
  Future<void> _handleRegister() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đồng ý với điều khoản!")),
      );
      return;
    }

    // So sánh trực tiếp với true để tránh lỗi operand bool
    final isValid = _formKey.currentState?.validate() ?? false;

    if (isValid) {
      setState(() => _isLoading = true);
      try {
        final dataSource = AuthRemoteDataSource();

        // Gửi đủ 4 tham số khớp với Backend
        final success = await dataSource.register(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _phoneController.text.trim(),
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng ký thành công!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(e.toString().replaceAll("Exception: ", "")),
                backgroundColor: Colors.redAccent
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 850;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // CỘT TRÁI: ẢNH NỀN
          if (!isMobile)
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=2000&auto=format&fit=crop'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(color: Colors.black.withOpacity(0.2)),
                  const Positioned(
                    bottom: 60, left: 50, right: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("FruitFresh", style: TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text("Mang hương vị tươi mát từ trang trại đến bàn ăn của bạn.",
                            style: TextStyle(color: Colors.white70, fontSize: 18)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // CỘT PHẢI: FORM
          Expanded(
            flex: 1,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Tạo tài khoản", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text("Tham gia FruitFresh để mua sắm nông sản sạch", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 32),

                        _buildInput("HỌ VÀ TÊN", "Nguyễn Văn A", _nameController),
                        const SizedBox(height: 16),
                        _buildInput("SỐ ĐIỆN THOẠI", "09xx xxx xxx", _phoneController),
                        const SizedBox(height: 16),
                        _buildInput("ĐỊA CHỈ EMAIL", "name@example.com", _emailController),
                        const SizedBox(height: 16),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildInput("MẬT KHẨU", "••••••••", _passwordController, isPass: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildInput("XÁC NHẬN", "••••••••", _confirmController, isPass: true)),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeTerms,
                              activeColor: primaryPurple,
                              onChanged: (v) => setState(() => _agreeTerms = v!),
                            ),
                            const Expanded(
                              child: Text("Tôi đồng ý với Điều khoản và Chính sách bảo mật",
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildRegisterButton(),
                        const SizedBox(height: 24),
                        const Center(child: Text("HOẶC TIẾP TỤC VỚI", style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1.2))),
                        const SizedBox(height: 16),
                        _buildGoogleButton(),
                        const SizedBox(height: 32),
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Đã có tài khoản? "),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text("Đăng nhập", style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
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

  // --- WIDGET INPUT DÙNG LOGIC CỦA BẢN CŨ ---
  Widget _buildInput(String label, String hint, TextEditingController ctrl, {bool isPass = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: isPass && _obscurePassword,
          validator: (v) {
            if (v == null || v.isEmpty) return "Bắt buộc";
            if (label == "XÁC NHẬN" && v != _passwordController.text) return "Mật khẩu không khớp";
            if (label == "ĐỊA CHỈ EMAIL" && !v.contains('@')) return "Email không hợp lệ";
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
            filled: true,
            fillColor: greyBg,
            suffixIcon: isPass ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ) : null,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: primaryPurple.withOpacity(0.5))),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        onPressed: _isLoading ? null : _handleRegister,
        child: _isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Đăng ký tài khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.network('https://www.svgrepo.com/show/475656/google_color.svg', width: 18),
            const SizedBox(width: 12),
            const Text("Tiếp tục với Google", style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}