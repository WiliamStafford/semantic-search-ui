import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/seller_dashboard_model.dart';

class AdminRemoteDataSource {
  static const String _apiBase = 'https://napping-squash-majorette.ngrok-free.dev/api/v1';

  Map<String, String> _getHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  Future<bool> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request;
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint("❌ Lỗi Admin API [Mã ${response.statusCode}]: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Lỗi mạng Admin: $e");
      return false;
    }
  }
  // Trong AdminRemoteDataSource.dart
  Future<List<Map<String, dynamic>>> getAdminRevenueList(String token) async {
    final response = await http.get(
      Uri.parse('$_apiBase/admin/reports/revenue'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      debugPrint("❌ Lỗi lấy danh sách doanh thu admin: ${response.statusCode}");
      return [];
    }
  }

  // Đảm bảo trong AdminRemoteDataSource.dart
  Future<SellerDashboardModel> getSellerDashboard(String token, int sellerId) async {
    final response = await http.get(Uri.parse('$_apiBase/admin/seller-products/$sellerId/dashboard'), headers: _getHeaders(token));

    if (response.statusCode == 200) {
      final dynamic body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is List) {
        return SellerDashboardModel.fromJson({"productsList": body});
      }
      return SellerDashboardModel.fromJson(body);
    }
    throw Exception('Lỗi API');
  }

  // Thêm sản phẩm cho Shop (Admin làm thay)
  Future<bool> addProductForAdmin(String token, int sellerId, Map<String, dynamic> data) =>
      _handleRequest(http.post(
          Uri.parse('$_apiBase/admin/seller-products/$sellerId/add'),
          headers: _getHeaders(token),
          body: jsonEncode(data)
      ));

  // Cập nhật sản phẩm cho Shop (Admin làm thay)
  Future<bool> updateProductForAdmin(String token, int sellerId, Map<String, dynamic> data) =>
      _handleRequest(http.put(
          Uri.parse('$_apiBase/admin/seller-products/$sellerId/update'),
          headers: _getHeaders(token),
          body: jsonEncode(data)
      ));

  // Xóa sản phẩm của Shop (Admin làm thay)
  Future<bool> deleteProductForAdmin(String token, int sellerId, int productId) =>
      _handleRequest(http.delete(
          Uri.parse('$_apiBase/admin/seller-products/$sellerId/delete/$productId'),
          headers: _getHeaders(token)
      ));

  // Cập nhật trạng thái đơn hàng (Admin làm thay)
  Future<bool> updateOrderStatusForAdmin(String token, int sellerId, int orderId, String status) =>
      _handleRequest(http.put(
          Uri.parse('$_apiBase/admin/seller-products/$sellerId/orders/$orderId/status?status=$status'),
          headers: _getHeaders(token)
      ));
}