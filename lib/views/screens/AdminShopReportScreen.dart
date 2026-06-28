import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../data/models/StatResponse.dart';
import '../../data/models/TopProductResponseAdmin.dart';

class AdminShopReportScreen extends StatefulWidget {
  final String token;
  final int sellerId;

  const AdminShopReportScreen({
    super.key,
    required this.token,
    required this.sellerId,
  });

  @override
  State<AdminShopReportScreen> createState() => _AdminShopReportScreenState();
}

class _AdminShopReportScreenState extends State<AdminShopReportScreen> {
  String _periodType = 'YEAR';

  Future<List<StatResponse>> _fetchRevenue() async {
    if (widget.sellerId <= 0) return [];
    try {
      final url = 'http://localhost:8080/api/v1/admin/reports/${widget.sellerId}/stats/period?periodType=$_periodType';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => StatResponse.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Lỗi fetch revenue: $e");
      return [];
    }
  }

  Future<List<TopProductResponseAdmin>> _fetchProducts() async {
    if (widget.sellerId <= 0) return [];

    // 1. Kiểm tra token trước khi gọi
    if (widget.token.isEmpty) {
      debugPrint("❌ Token bị trống!");
      return [];
    }

    try {
      final url = 'http://localhost:8080/api/v1/admin/reports/${widget.sellerId}/stats/products/top';

      // 2. Cấu hình Headers y hệt như Postman
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Thêm cái này để backend biết muốn nhận JSON
        },
      );

      // 3. Debug chi tiết
      debugPrint("Request URL: $url");
      debugPrint("Response Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => TopProductResponseAdmin.fromJson(e)).toList();
      } else {
        debugPrint("❌ Server trả về lỗi: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Lỗi kết nối: $e");
      return [];
    }
  }

  Widget _buildAreaChart(List<StatResponse> data) {
    if (data.isEmpty) return const SizedBox(height: 250, child: Center(child: Text("Không có dữ liệu")));
    final double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double maxY = maxValue == 0 ? 1 : maxValue * 1.2;

    return SizedBox(
      height: 250,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.3)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Doanh thu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: _periodType,
                items: ['YEAR', 'MONTH', 'WEEK'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _periodType = val!),
              ),
            ],
          ),
          FutureBuilder<List<StatResponse>>(
            key: ValueKey("${widget.sellerId}_$_periodType"),
            future: _fetchRevenue(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
              return _buildAreaChart(snapshot.data ?? []);
            },
          ),
          const SizedBox(height: 40),
          const Text("Top 10 sản phẩm bán chạy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<TopProductResponseAdmin>>(
            key: ValueKey("${widget.sellerId}"),
            future: _fetchProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Chưa có dữ liệu sản phẩm");

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Tên SP')),
                    DataColumn(label: Text('SL')),
                    DataColumn(label: Text('Doanh thu'))
                  ],
                  rows: snapshot.data!.map((p) => DataRow(cells: [
                    DataCell(Text(p.productId.toString())),
                    DataCell(Text(p.productName)),
                    DataCell(Text(p.totalSold.toString())),
                    DataCell(Text(NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(p.totalRevenue))),
                  ])).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}