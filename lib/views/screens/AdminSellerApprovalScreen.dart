import 'package:flutter/material.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../data/models/seller_registration_model.dart';
import '../../widgets/custom_admin_app_bar.dart';
import '../../widgets/seller_request_card.dart';

class AdminSellerApprovalScreen extends StatefulWidget {
  final String accessToken;
  const AdminSellerApprovalScreen({super.key, required this.accessToken});

  @override
  State<AdminSellerApprovalScreen> createState() => _AdminSellerApprovalScreenState();
}

class _AdminSellerApprovalScreenState extends State<AdminSellerApprovalScreen> {
  late Future<List<SellerRegistration>> _sellersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _sellersFuture = UserRemoteDataSource().getPendingSellers(widget.accessToken);
    });
  }

  Future<void> _approve(int id) async {
    try {
      await UserRemoteDataSource().approveSeller(widget.accessToken, id);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã duyệt Seller thành công!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi duyệt: $e")));
    }
  }

  Future<void> _reject(int id) async {
    try {
      await UserRemoteDataSource().rejectSeller(widget.accessToken, id);
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã từ chối đơn đăng ký!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi từ chối: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAdminAppBar(title: "Duyệt đăng ký Seller"),
      body: FutureBuilder<List<SellerRegistration>>(
        future: _sellersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text("Có lỗi xảy ra: ${snapshot.error}"));
          final data = snapshot.data ?? [];

          if (data.isEmpty) return const Center(child: Text("Không có đơn chờ duyệt."));

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              return SellerRequestCard(
                seller: data[index],
                onApprove: () => _approve(data[index].id),
                onReject: () => _reject(data[index].id),
              );
            },
          );
        },
      ),
    );
  }
}