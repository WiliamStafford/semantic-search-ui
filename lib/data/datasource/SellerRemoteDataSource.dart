import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/seller_dashboard_model.dart';

class SellerRemoteDataSource {
  // Gom base URL vào đây
  static const String _apiBase = 'https://napping-squash-majorette.ngrok-free.dev/api/v1';

  // Helper để tạo headers chung
  Map<String, String> _getHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'ngrok-skip-browser-warning': 'any',
  };

  // 🌟 ĐÃ SỬA: Nâng cấp hàm xử lý request để in ra nguyên nhân lỗi từ Backend
  Future<bool> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request;

      // Chấp nhận cả mã 200 (OK) và 201 (Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Nếu thất bại, in ra chính xác lỗi mà Spring Boot trả về
        debugPrint("❌ Lỗi API [Mã ${response.statusCode}]: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Lỗi mạng hoặc Exception: $e");
      return false;
    }
  }

  Future<SellerDashboardModel> getDashboardData(String token) async {
    final response = await http.get(
      Uri.parse('$_apiBase/seller/orders/dashboard/summary'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return SellerDashboardModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    // In ra lỗi body nếu API get Dashboard xịt
    debugPrint("Lỗi Dashboard Body: ${response.body}");
    throw Exception('Lỗi lấy Dashboard (Mã: ${response.statusCode})');
  }

  Future<List<dynamic>> getSellerOrders(String token) async {
    final response = await http.get(
      Uri.parse('$_apiBase/seller/orders'),
      headers: _getHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Lỗi lấy danh sách đơn hàng (Mã: ${response.statusCode})');
  }

  Future<bool> addProduct(String token, Map<String, dynamic> data) =>
      _handleRequest(http.post(Uri.parse('$_apiBase/products/seller/add'), headers: _getHeaders(token), body: jsonEncode(data)));

  // 1. HÀM CẬP NHẬT SẢN PHẨM (PUT)
  Future<bool> updateProduct(String token, Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse('$_apiBase/products/seller/update'),
        headers: {
          'Authorization': 'Bearer $token', // 🌟 BẮT BUỘC PHẢI CÓ ĐỂ KHÔNG BỊ 403
          'Content-Type': 'application/json; charset=UTF-8', // 🌟 BẮT BUỘC để SpringBoot đọc được @RequestBody
          'ngrok-skip-browser-warning': 'true'
        },
        body: jsonEncode(updatedData),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Lỗi Update API: Mã ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Lỗi gọi API Update: $e");
      return false;
    }
  }

  // 2. HÀM XÓA SẢN PHẨM (DELETE)
  Future<bool> deleteProduct(String token, int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_apiBase/products/seller/$productId'),
        headers: {
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true'
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Lỗi Delete API: Mã ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Lỗi gọi API Delete: $e");
      return false;
    }
  }
  Future<bool> updateOrderStatus(String token, int id, String status) =>
      _handleRequest(http.put(Uri.parse('$_apiBase/seller/orders/$id/status?status=$status'), headers: _getHeaders(token)));
}