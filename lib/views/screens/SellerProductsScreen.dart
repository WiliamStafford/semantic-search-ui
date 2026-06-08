import 'package:flutter/material.dart';
class SellerProductsScreen extends StatelessWidget {
  final String accessToken;
  const SellerProductsScreen({super.key, required this.accessToken});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text("Quản lý sản phẩm Seller")));
}