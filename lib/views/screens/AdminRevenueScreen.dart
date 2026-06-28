import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/datasource/AdminRemoteDataSource.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../widgets/custom_admin_app_bar.dart';
import 'AdminShopReportScreen.dart';

class AdminRevenueScreen extends StatefulWidget {
  final String accessToken;

  const AdminRevenueScreen({super.key, required this.accessToken});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  late Future<List<Map<String, dynamic>>> _revenueFuture;

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  void _loadRevenueData() {
    _revenueFuture = AdminRemoteDataSource().getAdminRevenueList(widget.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAdminAppBar(title: "Doanh thu từng Cửa hàng"),
      body: RefreshIndicator(
        onRefresh: () async => setState(() => _loadRevenueData()),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _revenueFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Chưa có dữ liệu."));
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) => ShopRevenueTile(
                    item: snapshot.data![index],
                    token: widget.accessToken,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ShopRevenueTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String token;

  const ShopRevenueTile({super.key, required this.item, required this.token});

  @override
  Widget build(BuildContext context) {
    // 1. Dùng print để in ra chính xác cấu trúc dữ liệu đang nhận được
    debugPrint("DEBUG - Dữ liệu item: $item");

    // 2. Thử tất cả các khả năng của key (dùng chuỗi || thay vì ??)
    final String shopName = (item['shopName'] ?? item['shop_name'] ?? item['sellerName'] ?? "Chưa đặt tên").toString();

    // 3. Ép kiểu an toàn, hỗ trợ cả trường hợp ID là String hoặc int
    final dynamic idRaw = item['sellerId'] ?? item['user_id'] ?? item['userId'] ?? item['id'] ?? 0;
    final int sellerId = (idRaw is num) ? idRaw.toInt() : int.tryParse(idRaw.toString()) ?? 0;

    // 4. Format doanh thu an toàn
    final dynamic revRaw = item['totalRevenue'] ?? item['total_revenue'] ?? 0.0;
    final double revenue = (revRaw is num) ? revRaw.toDouble() : 0.0;
    final String formattedRevenue = NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(revenue);

    return Card(
      // ... giữ nguyên giao diện
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.store, color: Colors.green),
        ),
        title: Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Tổng doanh thu: $formattedRevenue"),
        children: [
          sellerId > 0
              ? Container(
            height: 500,
            padding: const EdgeInsets.all(16),
            child: AdminShopReportScreen(token: token, sellerId: sellerId),
          )
              : const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("ID cửa hàng không hợp lệ (ID=0)", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}