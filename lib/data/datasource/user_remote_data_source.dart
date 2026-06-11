import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/seller_registration_model.dart';
import '../models/user_model.dart';

class UserRemoteDataSource {
  static const String baseUrl = "http://localhost:8080/api/v1";

  Future<List<Map<String, dynamic>>> getSellerRevenue(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/A_Order/revenue/sellers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      List<dynamic> list = jsonDecode(utf8.decode(response.bodyBytes));
      return list.map((item) => Map<String, dynamic>.from(item)).toList();
    } else {
      throw Exception("Không thể lấy dữ liệu doanh thu: ${response.statusCode}");
    }
  }

  Future<List<SellerRegistration>> getPendingSellers(String accessToken) async {
    final url = Uri.parse('$baseUrl/admin/sellers/pending');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((dynamic item) => SellerRegistration.fromJson(item)).toList();
    } else {
      throw Exception("Lỗi ${response.statusCode}: ${response.body}");
    }
  }

  Future<void> approveSeller(String token, int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/sellers/$id/approve'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception("Duyệt thất bại: ${response.body}");
    }
  }

  Future<String> getSellerRegistrationStatus(String accessToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/user/seller-registration/status'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return response.body.replaceAll('"', '');
    }
    return 'NOT_REGISTERED';
  }

  Future<UserModel> getUserProfile(String token) async {
    if (token.isEmpty) {
      throw Exception('Phiên đăng nhập không hợp lệ (Token rỗng)');
    }

    final uri = Uri.parse('$baseUrl/user/profile');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      dev.log('GET Profile Status: ${response.statusCode}', name: 'UserAPI');

      switch (response.statusCode) {
        case 200:
          return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        case 401:
          throw Exception('Phiên đăng nhập hết hạn');
        case 403:
          throw Exception('Bạn không có quyền truy cập thông tin này');
        case 404:
          throw Exception('Không tìm thấy API: $uri');
        default:
          throw Exception('Lỗi hệ thống: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Không thể kết nối đến Server: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> updateProfile(String token, Map<String, dynamic> updateData) async {
    final uri = Uri.parse('$baseUrl/user/update_profile');

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      dev.log('PUT Update Status: ${response.statusCode}', name: 'UserAPI');

      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        final errorMsg = jsonDecode(utf8.decode(response.bodyBytes))['message'] ?? 'Cập nhật thất bại';
        throw Exception(errorMsg);
      }
    } catch (e) {
      dev.log('Update Error: $e', name: 'UserAPI', error: e);
      rethrow;
    }
  }

  Future<void> registerSeller(String accessToken, Map<String, String> request) async {
    final uri = Uri.parse('$baseUrl/user/seller-registration');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request),
      );

      dev.log('POST Seller Registration Status: ${response.statusCode}', name: 'UserAPI');

      if (response.statusCode != 200) {
        final responseBody = jsonDecode(utf8.decode(response.bodyBytes));
        final errorMessage = responseBody['message'] ?? 'Đăng ký không thành công';
        throw Exception(errorMessage);
      }
    } catch (e) {
      dev.log('Seller Registration Error: $e', name: 'UserAPI', error: e);
      rethrow;
    }
  }

  Future<void> rejectSeller(String accessToken, int id) async {
    final uri = Uri.parse('$baseUrl/admin/sellers/$id/reject');

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      dev.log('POST Reject Seller Status: ${response.statusCode}', name: 'UserAPI');

      if (response.statusCode != 200) {
        throw Exception("Từ chối thất bại: ${response.body}");
      }
    } catch (e) {
      dev.log('Reject Seller Error: $e', name: 'UserAPI', error: e);
      rethrow;
    }
  }
  // --- THÊM VÀO UserRemoteDataSource ---

  // Lấy toàn bộ User
  Future<List<UserModel>> getAllUsers(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'), // Chỉnh sửa endpoint cho đúng với API backend của bạn
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((item) => UserModel.fromJson(item)).toList();
    }
    throw Exception("Không thể tải danh sách User");
  }

  // Lấy toàn bộ Shop
  Future<List<SellerRegistration>> getAllShops(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/sellers'), // Chỉnh sửa endpoint cho đúng với API backend của bạn
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      return body.map((item) => SellerRegistration.fromJson(item)).toList();
    }
    throw Exception("Không thể tải danh sách Shop");
  }

  // Khóa User
  Future<void> blockUser(String token, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users/$userId/block'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception("Lỗi khóa User");
  }

  // Đóng Shop
  Future<void> closeShop(String token, int shopId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/shops/$shopId/close'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception("Lỗi đóng Shop");
  }
}