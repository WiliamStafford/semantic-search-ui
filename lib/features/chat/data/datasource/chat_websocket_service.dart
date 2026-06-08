import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatWebSocketService {
  late StompClient stompClient;
  final Function(Map<String, dynamic>) onMessageReceived;
  final String conversationId;

  ChatWebSocketService({required this.conversationId, required this.onMessageReceived});

  void connect(String token) {
    stompClient = StompClient(
      config: StompConfig(
        url: 'wss://napping-squash-majorette.ngrok-free.dev/ws-chat',
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: (StompFrame frame) {
          stompClient.subscribe(
            destination: '/topic/messages/$conversationId',
            callback: (StompFrame frame) {
              if (frame.body != null) {
                onMessageReceived(json.decode(frame.body!));
              }
            },
          );
        },
        onWebSocketError: (dynamic error) => print("Lỗi WebSocket: $error"),
      ),
    );
    stompClient.activate();
  }

  void sendMessage(String content, int senderId, int receiverId, int productSellerId, {String type = 'text'}) {
    stompClient.send(
      destination: '/app/chat/$conversationId',
      body: json.encode({
        'senderId': senderId.toString(),
        'receiverId': receiverId.toString(),
        'content': content,
        'productSellerId': productSellerId.toString(),
        'type': type,
      }),
    );
  }

  void disconnect() {
    stompClient.deactivate();
  }
}