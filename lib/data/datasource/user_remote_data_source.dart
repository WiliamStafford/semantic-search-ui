import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserRemoteDataSource {
  static const String baseUrl = "http://localhost:8080/api/v1";

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
}