import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final String baseUrl = "http://localhost:8080/api/v1/products";

  Future<List<ProductModel>> getHomeProducts(String token) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/active"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => ProductModel.fromJson(json)).toList();
      } else {
        throw Exception("Server trả về lỗi: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Lỗi kết nối: $e");
    }
  }
}