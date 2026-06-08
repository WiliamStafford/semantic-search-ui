import 'package:http/http.dart' as http;

class CartRemoteDataSource {
  final String baseUrl = 'https://napping-squash-majorette.ngrok-free.dev/api/v1/cart';

  Future<bool> addToCart({
    required String token,
    required int userId,
    required int sellerProductId,
    required int quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add?userId=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': 'any',
      },
      body: '{"sellerProductId": $sellerProductId, "quantity": $quantity}',
    );
    return response.statusCode == 200;
  }
}