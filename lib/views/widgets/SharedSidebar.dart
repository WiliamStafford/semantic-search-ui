import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:semantic_search_ui/features/auth/presentation/pages/login_page.dart';
import '../theme/fruit_colors.dart';

class SharedSidebar extends StatelessWidget {
  final String currentSpace;
  final String activeRoute;
  final String accessToken;
  final Function(String space, String route) onSpaceChanged;

  const SharedSidebar({
    super.key,
    required this.currentSpace,
    required this.activeRoute,
    required this.accessToken,
    required this.onSpaceChanged,
  });

  bool _hasRole(String roleName) {
    try {
      final decodedToken = JwtDecoder.decode(accessToken);
      final roles = decodedToken['roles'] ?? decodedToken['authorities'] ?? [];
      return roles.contains(roleName);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeller = _hasRole("ROLE_SELLER");
    final bool isAdmin = _hasRole("ROLE_ADMIN");

    return Container(
      width: 260,
      color: FruitColors.primaryGreen,
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: Colors.white24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                if (currentSpace == "CUSTOMER") ..._buildCustomerMenu(),
                if (currentSpace == "SELLER") ..._buildSellerMenu(),
                if (currentSpace == "ADMIN") ..._buildAdminMenu(),
              ],
            ),
          ),

          if (isSeller || isAdmin) _buildWorkspaceSwitcher(isSeller, isAdmin),

          const Divider(height: 1, color: Colors.white24),
          _buildMenuItem(
            icon: Icons.logout_rounded,
            title: "Đăng xuất",
            isActive: false,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('accessToken');
              if (context.mounted)
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildCustomerMenu() => [
    _buildMenuItem(
      icon: Icons.home_rounded,
      title: "Trang chủ",
      isActive: activeRoute == "home",
      onTap: () => onSpaceChanged("CUSTOMER", "home"),
    ),
    _buildMenuItem(
      icon: Icons.favorite_border_rounded,
      title: "Wishlist",
      isActive: activeRoute == "wishlist",
      onTap: () => onSpaceChanged("CUSTOMER", "wishlist"),
    ),
    _buildMenuItem(
      icon: Icons.shopping_cart_outlined,
      title: "Giỏ hàng",
      isActive: activeRoute == "cart",
      onTap: () => onSpaceChanged("CUSTOMER", "cart"),
    ),
    _buildMenuItem(
      icon: Icons.receipt_long_rounded,
      title: "Đơn hàng",
      isActive: activeRoute == "order-history",
      onTap: () => onSpaceChanged("CUSTOMER", "order-history"),
    ),
    _buildMenuItem(
      icon: Icons.assignment_return_outlined,
      title: "Đổi trả",
      isActive: activeRoute == "return-history",
      onTap: () => onSpaceChanged("CUSTOMER", "return-history"),
    ),
    _buildMenuItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: "Hội thoại",
      isActive: activeRoute == "chat",
      onTap: () => onSpaceChanged("CUSTOMER", "chat"),
    ),
    _buildMenuItem(
      icon: Icons.person_outline_rounded,
      title: "Hồ sơ",
      isActive: activeRoute == "profile",
      onTap: () => onSpaceChanged("CUSTOMER", "profile"),
    ),
  ];

  // --- MENU CỦA SELLER ---
  List<Widget> _buildSellerMenu() => [
    _buildMenuItem(
      icon: Icons.dashboard_rounded,
      title: "Tổng quan",
      isActive: activeRoute == "seller-dashboard",
      onTap: () => onSpaceChanged("SELLER", "seller-dashboard"),
    ),
    _buildMenuItem(
      icon: Icons.assignment_rounded,
      title: "Đơn hàng",
      isActive: activeRoute == "seller-orders",
      onTap: () => onSpaceChanged("SELLER", "seller-orders"),
    ),
    _buildMenuItem(
      icon: Icons.assignment_return_outlined,
      title: "Khiếu nại / Đổi trả",
      isActive: activeRoute == "seller-returns",
      onTap: () => onSpaceChanged("SELLER", "seller-returns"),
    ),
    _buildMenuItem(
      icon: Icons.chat_bubble_outline_rounded,
      title: "Hội thoại",
      isActive: activeRoute == "seller-chat",
      onTap: () => onSpaceChanged("SELLER", "seller-chat"),
    ),
    _buildMenuItem(
      icon: Icons.bar_chart_rounded,
      title: "Thống kê doanh thu",
      isActive: activeRoute == "seller-stats",
      onTap: () => onSpaceChanged("SELLER", "seller-stats"),
    ),
    const SizedBox(height: 20),
    _buildSpaceButton(
      "Quay lại Mua sắm",
      Icons.arrow_back,
      () => onSpaceChanged("CUSTOMER", "home"),
    ),
  ];

  Widget _buildWorkspaceSwitcher(bool isSeller, bool isAdmin) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Column(
      children: [
        if (currentSpace != "SELLER" && isSeller)
          _buildSpaceButton(
            "Seller Workspace",
            Icons.storefront,
            () => onSpaceChanged("SELLER", "seller-dashboard"),
          ),
        if (currentSpace != "ADMIN" && isAdmin)
          _buildSpaceButton(
            "Admin Console",
            Icons.admin_panel_settings,
            () => onSpaceChanged("ADMIN", "admin-dashboard"),
          ),
      ],
    ),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(24),
    child: Row(
      children: [
        Icon(_getSpaceIcon(), color: Colors.white, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _getSpaceTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  String _getSpaceTitle() =>
      currentSpace == "SELLER" ? "Seller Workspace" : "FruitFresh Sàn";

  IconData _getSpaceIcon() =>
      currentSpace == "SELLER" ? Icons.storefront_rounded : Icons.eco_rounded;

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) => ListTile(
    leading: Icon(icon, color: isActive ? Colors.white : Colors.white60),
    title: Text(
      title,
      style: TextStyle(
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: Colors.white,
        fontSize: 14,
      ),
    ),
    selected: isActive,
    selectedTileColor: Colors.white.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    onTap: onTap,
  );

  Widget _buildSpaceButton(String title, IconData icon, VoidCallback onTap) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.all(12),
          ),
          onPressed: onTap,
          icon: Icon(icon, size: 16),
          label: Text(title, style: const TextStyle(fontSize: 12)),
        ),
      );

  List<Widget> _buildAdminMenu() => [
    _buildMenuItem(
      icon: Icons.dashboard_customize_rounded,
      title: "Dashboard",
      isActive: activeRoute == "admin-dashboard",
      onTap: () => onSpaceChanged("ADMIN", "admin-dashboard"),
    ),
    _buildMenuItem(
      icon: Icons.store_mall_directory_rounded,
      title: "Quản lý Shop",
      isActive: activeRoute == "admin-shops",
      onTap: () => onSpaceChanged("ADMIN", "admin-shops"),
    ),
    _buildMenuItem(
      icon: Icons.storefront_sharp,
      title: "Duyệt Seller",
      isActive: activeRoute == "admin-sellers",
      onTap: () => onSpaceChanged("ADMIN", "admin-sellers"),
    ),
    _buildMenuItem(
      icon: Icons.analytics_outlined,
      title: "Doanh thu Seller",
      isActive: activeRoute == "admin-revenue",
      onTap: () => onSpaceChanged("ADMIN", "admin-revenue"),
    ),
    const SizedBox(height: 20),
    _buildSpaceButton(
      "Quay lại Mua sắm",
      Icons.arrow_back,
          () => onSpaceChanged("CUSTOMER", "home"),
    ),
  ];
}
