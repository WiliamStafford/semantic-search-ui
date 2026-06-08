// lib/views/screens/MainLayoutScreen.dart
import 'package:flutter/material.dart';
import '../theme/fruit_colors.dart';
import '../widgets/SharedSidebar.dart';

import 'FruitHomeScreen.dart';
import 'CartScreen.dart';
import 'OrderHistoryScreen.dart';
import 'PaymentHistoryScreen.dart';
import 'ReturnHistoryScreen.dart';
import 'FruitProfileScreen.dart';
import 'ConversationListScreen.dart';
import 'SellerDashboardScreen.dart';
import 'SellerOrdersScreen.dart';
import 'SellerProductsScreen.dart';
import 'SellerReturnScreen.dart';
import 'SemanticSearchScreen.dart';
import 'WishListScreen.dart';

// import 'AdminDashboardScreen.dart';

class MainLayoutScreen extends StatefulWidget {
  final bool isSellerMode;
  final String accessToken;

  const MainLayoutScreen({super.key, required this.accessToken,this.isSellerMode = false});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  String _currentSpace = "CUSTOMER";
  String _activeRoute = "home";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF1E2D20),
            child: SharedSidebar(
              activeRoute: _activeRoute,
              accessToken: widget.accessToken,
              currentSpace: _currentSpace,
              onSpaceChanged: (space, route) {
                setState(() {
                  _currentSpace = space;
                  _activeRoute = route;
                });
              },
            ),
          ),

          Expanded(
            child: Container(
              color: FruitColors.background, // Màu nền trang chủ
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    // Phân nhánh theo Workspace (Space)
    if (_currentSpace == "SELLER") {
      switch (_activeRoute) {
        case "seller-dashboard":
          return SellerDashboardScreen(
            key: const ValueKey("seller-db"),
            accessToken: widget.accessToken,
          );
        case "seller-orders":
          return SellerOrdersScreen(
            key: const ValueKey("seller-ord"),
            accessToken: widget.accessToken,
          );
        case "seller-products":
          return SellerProductsScreen(
            key: const ValueKey("seller-prod"),
            accessToken: widget.accessToken,
          );
        case "seller-returns":
          return SellerReturnScreen(
            key: const ValueKey("seller-ret"),
            accessToken: widget.accessToken,
          );
        case "seller-chat":
          return ConversationListScreen(
            key: const ValueKey("seller-chat"),
            accessToken: widget.accessToken,
            isSellerMode: true,
          );
        default:
          return SellerDashboardScreen(
            key: const ValueKey("seller-db"),
            accessToken: widget.accessToken,
          );
      }
    } else if (_currentSpace == "ADMIN") {
      switch (_activeRoute) {
        // case "admin-dashboard": return AdminDashboardScreen(...);
        default:
          return const Center(child: Text("Admin Console: Đang phát triển..."));
      }
    } else {
      switch (_activeRoute) {
        case "home":
          return FruitHomeScreen(
            key: const ValueKey("cust-home"),
            accessToken: widget.accessToken,
          );
        // case "ai-search":return SemanticSearchScreen(key: const ValueKey("cust-ai"), accessToken: widget.accessToken);
        case "cart":
          return CartScreen(
            key: const ValueKey("cust-cart"),
            accessToken: widget.accessToken,
          );
        case "order-history":
          return OrderHistoryScreen(
            key: const ValueKey("cust-orders"),
            accessToken: widget.accessToken,
          );
        case "payment-history":
          return PaymentHistoryScreen(
            key: const ValueKey("cust-pay"),
            accessToken: widget.accessToken,
          );
        case "return-history":
          return ReturnHistoryScreen(
            key: const ValueKey("cust-return"),
            accessToken: widget.accessToken,
            userId: 0,
          );
        case "profile":
          return FruitProfileScreen(
            key: const ValueKey("cust-prof"),
            accessToken: widget.accessToken,
          );
        case "chat":
          return ConversationListScreen(
            key: const ValueKey("cust-chat"),
            accessToken: widget.accessToken,
            isSellerMode: false,
          );
        case "wishlist":
          return WishListScreen(
            key: const ValueKey("cust-wishlist"),
            accessToken: widget.accessToken,
          );
        default:
          return FruitHomeScreen(
            key: const ValueKey("cust-home"),
            accessToken: widget.accessToken,
          );
      }
    }
  }
}
