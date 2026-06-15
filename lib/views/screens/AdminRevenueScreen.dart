import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../widgets/custom_admin_app_bar.dart';

class AdminRevenueScreen extends StatefulWidget {
  final String accessToken;
  const AdminRevenueScreen({super.key, required this.accessToken});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  Future<List<Map<String, dynamic>>>? _revenueFuture;
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _revenueFuture = UserRemoteDataSource().getSellerRevenue(widget.accessToken);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], //
      appBar:const CustomAdminAppBar(title: "Dashboard"),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _revenueFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu."));
          }

          final data = snapshot.data!;

          // Bố cục căn giữa màn hình cho Dashboard chuyên nghiệp
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text("Doanh thu theo Cửa hàng",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columnSpacing: 40,
                        headingRowColor: WidgetStateProperty.all(Colors.green[50]),
                        columns: const [
                          DataColumn(label: Text("Tên Cửa Hàng", style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text("Đơn hàng", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                          DataColumn(label: Text("Doanh thu", style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        ],
                        rows: data.map((item) {
                          final shopName = item['sellerName']?.toString() ?? "Chưa đặt tên";
                          final orderCount = item['totalOrders'] ?? 0;
                          final totalRevenue = (item['totalRevenue'] as num?)?.toDouble() ?? 0.0;

                          return DataRow(cells: [
                            DataCell(Text(shopName, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(orderCount.toString())),
                            DataCell(Text(_currencyFormat.format(totalRevenue),
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}