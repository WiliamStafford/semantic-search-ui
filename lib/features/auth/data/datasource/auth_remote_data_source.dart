import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../../../../data/models/user_model.dart';
// lib/features/auth/data/datasource/auth_remote_data_source.dart

class AuthRemoteDataSource {
  final Dio _dio = Dio();

  final String _baseUrl = "http://localhost:8080/api/v1/auth";

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/login",
        data: {
          "email": email,
          "password": password,
          "authType": "PASSWORD",
        },
      );
      return response.data;
    } on DioException catch (e) {

      print("Mã lỗi HTTP: ${e.response?.statusCode}");
      print("Chi tiết lỗi: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối");
    }
  }
  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/register",
        data: {
          "email": email,
          "password": password,
          "fullName": fullName,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi đăng ký");
    }
  }

  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/forgot-password",
        data: {"email": email},
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? "Không thể gửi mã reset");
    }
  }

  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post(
        "$_baseUrl/reset-password",
        data: {
          "email": email,
          "code": code,
          "newPassword": newPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? "Mã xác nhận không chính xác");
    }
  }

  Future<UserModel> updateProfile(String token, Map<String, dynamic> updateData) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/user/update_profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else if (response.statusCode == 403) {
      throw Exception('Bạn không có quyền thực hiện hành động này (403)');
    } else {
      throw Exception('Lỗi server: ${response.statusCode}');
    }
  }
}