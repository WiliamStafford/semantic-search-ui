import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../../../data/models/user_model.dart';
import '../../../../config/app_config.dart';

// lib/features/auth/data/datasource/auth_remote_data_source.dart

class AuthRemoteDataSource {
  final Dio _dio = Dio();

  // Lấy baseUrl từ AppConfig để dễ bảo trì
  final String _authUrl = "${AppConfig.baseUrl}/api/v1/auth";
  final String _userUrl = "${AppConfig.baseUrl}/api/v1/user";

  // 1. ĐĂNG NHẬP
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        "$_authUrl/login",
        data: {
          "email": email,
          "password": password,
          "authType": "PASSWORD",
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối server");
    }
  }

  // 2. ĐĂNG KÝ (Đã fix 4 tham số khớp với UI mới của Hùng)
  Future<bool> register(String email, String password, String name, String phone) async {
    try {
      final response = await _dio.post(
        "$_authUrl/register",
        data: {
          "email": email,
          "password": password,
          "fullName": name,
          "phoneNumber": phone, // Khớp với @JsonProperty("phoneNumber") bên Java
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi đăng ký tài khoản");
    }
  }

  // 3. QUÊN MẬT KHẨU (Gửi mã OTP)
  Future<String> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        "$_authUrl/forgot-password",
        data: {"email": email},
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? "Không thể gửi mã reset");
    }
  }

  // 4. RESET MẬT KHẨU (Xác nhận mã OTP và đặt pass mới)
  // 4. RESET MẬT KHẨU (Sửa lại thứ tự tham số cho khớp với UI)
  Future<String> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await _dio.post(
        "$_authUrl/reset-password",
        data: {
          "email": email,
          "code": code,
          "newPassword": newPassword,
        },
        options: Options(responseType: ResponseType.plain),
      );
      return response.data.toString();
    } on DioException catch (e) {
      String errorMsg = "Mã xác nhận không chính xác";
      debugPrint("Lỗi từ server: ${e.response?.data}");

      if (e.response?.data is Map) {
        errorMsg = e.response?.data['message'] ?? errorMsg;
      }
      throw Exception(errorMsg);
    }
  }

  // 5. CẬP NHẬT PROFILE (Đã chuyển từ http sang Dio)
  Future<UserModel> updateProfile(String token, Map<String, dynamic> updateData) async {
    try {
      final response = await _dio.put(
        "$_userUrl/update_profile",
        data: updateData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('Bạn không có quyền thực hiện hành động này (403)');
      }
      throw Exception(e.response?.data['message'] ?? "Lỗi cập nhật thông tin");
    }
  }
}