// chat_api_service.dart
import 'package:http/http.dart' as http;

import '../../../../config/app_config.dart';

Future<bool> deleteConversationApi(int conversationId, String token) async {
  final response = await http.delete(
    Uri.parse('${AppConfig.baseUrl}/api/v1/chat/conversation/$conversationId'),
    headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
  );
  return response.statusCode == 200;
}