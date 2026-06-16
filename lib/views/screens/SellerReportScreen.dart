import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

import '../../data/models/StatResponse.dart';
import '../../data/models/TopProductResponse.dart';

const String BASE_URL = 'http://localhost:8080/api/v1/seller/stats';

class SellerReportScreen extends StatefulWidget {
  final String token;
  SellerReportScreen({required this.token});

  @override
  _SellerReportScreenState createState() => _SellerReportScreenState();
}
class SellerTopBar extends StatelessWidget {
  const SellerTopBar({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: const Row(
        children: [
          Icon(Icons.storefront, color: Colors.green, size: 24),
          SizedBox(width: 8),
          Text(
            "Thống Kê Doanh Thu",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

class _SellerReportScreenState extends State<SellerReportScreen> {
  // 1. Khai báo biến trạng thái cho bộ lọc
  String _periodType = 'YEAR';

  Future<List<StatResponse>> _fetchRevenue() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/stats/period?periodType=$_periodType'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      return response.statusCode == 200
          ? (json.decode(response.body) as List)
          .map((e) => StatResponse.fromJson(e))
          .toList()
          : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<TopProductResponse>> _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/products/top'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      return response.statusCode == 200
          ? (json.decode(response.body) as List)
          .map((e) => TopProductResponse.fromJson(e))
          .toList()
          : [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Chèn thanh Top Bar
          const SellerTopBar(),

          // 2. Nội dung chính
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Biểu đồ doanh thu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: _periodType,
                        items: ['YEAR', 'MONTH', 'WEEK'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _periodType = val!;
                          });
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  FutureBuilder<List<StatResponse>>(
                    key: ValueKey(_periodType),
                    future: _fetchRevenue(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.isEmpty)
                        return Container(height: 200, alignment: Alignment.center, child: Text("Chưa có dữ liệu"));
                      return _buildAreaChart(snapshot.data!);
                    },
                  ),

                  SizedBox(height: 40),
                  Text("Top sản phẩm bán chạy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                  // --- BẢNG SẢN PHẨM ---
                  FutureBuilder<List<TopProductResponse>>(
                    future: _fetchProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.isEmpty)
                        return Text("Chưa có dữ liệu sản phẩm");

                      return Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text('Tên SP')),
                                  DataColumn(label: Text('SL')),
                                  DataColumn(label: Text('Doanh thu')),
                                ],
                                rows: snapshot.data!.map((p) => DataRow(cells: [
                                  DataCell(Text(p.productName)),
                                  DataCell(Text(p.totalSold.toString())),
                                  DataCell(Text("${p.totalRevenue.toStringAsFixed(0)} VND")),
                                ])).toList(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChart(List<StatResponse> data) {
    final double maxValue = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double maxY = maxValue == 0 ? 1 : maxValue * 1.2;

    final int labelInterval = (data.length / 5).ceil();

    return Container(
      height: 250, // Ép chiều cao cố định
      width: double.infinity, // Hoặc đặt width cụ thể ví dụ: 350
      padding: EdgeInsets.only(right: 16),
      child: AspectRatio(
        aspectRatio: 2.5,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(show: true, horizontalInterval: maxY / 5),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1, // Ép hiển thị tất cả các mốc (1, 2, 3...)
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();

                    // Kiểm tra nếu index nằm trong phạm vi dữ liệu thì mới hiển thị
                    if (index >= 0 && index < data.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          data[index].label,
                          style: TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return SizedBox();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45, // Tăng thêm diện tích để số to không bị cắt
                  interval: maxY / 5, // Đảm bảo khoảng cách giữa các số là cố định
                  getTitlesWidget: (value, meta) {
                    String text = '';
                    if (value >= 1000000) {
                      text = '${(value / 1000000).toStringAsFixed(1)}M';
                    } else {
                      text = '${(value / 1000).toStringAsFixed(0)}K';
                    }
                    return Text(text, style: TextStyle(fontSize: 10), textAlign: TextAlign.right);
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList(),
                isCurved: true,
                curveSmoothness: 0.35,
                color: Colors.green,
                barWidth: 4,
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withOpacity(0.3),
                  cutOffY: 0,
                  applyCutOffY: true,
                ),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}