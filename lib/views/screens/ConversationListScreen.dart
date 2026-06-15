import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../config/app_config.dart';
import '../../data/datasource/user_remote_data_source.dart';
import '../../features/chat/presentation/pages/chat_screen.dart';
import '../theme/fruit_colors.dart';
import '../../features/chat/data/datasource/chat_api_service.dart';

class ConversationListScreen extends StatefulWidget {
  final String accessToken;
  final bool isSellerMode;

  const ConversationListScreen({
    super.key,
    required this.accessToken,
    required this.isSellerMode,
  });

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  List<dynamic> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    print("DEBUG: Bắt đầu gọi API danh sách hội thoại...");
    try {
      final String mode = widget.isSellerMode ? "SELLER" : "CUSTOMER";
      final url = Uri.parse(
        '${AppConfig.baseUrl}/api/v1/chat/conversations?mode=$mode',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      print("DEBUG: Mode: $mode | Status Code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _conversations = data.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        print("DEBUG: API Lỗi: ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Exception khi gọi API: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: FruitColors.accentGreen,
                    ),
                  )
                : _conversations.isEmpty
                ? const Center(child: Text("Chưa có hội thoại nào"))
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.builder(
                      itemCount: _conversations.length,
                      itemBuilder: (context, index) {
                        final conv = _conversations[index];

                        final String title =
                            conv['productName']?.toString() ?? "Hội thoại";
                        final String? imageUrl = conv['productImageUrl']
                            ?.toString();
                        final String lastMessage =
                            conv['lastMessage']?.toString() ??
                            "Chưa có tin nhắn";

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: FruitColors.primaryGreen
                                .withOpacity(0.1),
                            backgroundImage:
                                (imageUrl != null &&
                                    imageUrl.startsWith('http'))
                                ? NetworkImage(imageUrl)
                                : null,
                            child:
                                (imageUrl == null ||
                                    !imageUrl.startsWith('http'))
                                ? Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : "?",
                                  )
                                : null,
                          ),
                          title: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _confirmDelete(conv['id'] ?? 0),
                          ),
                          onTap: () async {
                            final user = await UserRemoteDataSource()
                                .getUserProfile(widget.accessToken);
                            final myCurrentUserId = user.id;
                            final int targetUserId =
                                (conv['senderId'] == myCurrentUserId)
                                ? conv['receiverId']
                                : conv['senderId'];

                            if (!mounted) return;

                            final shouldRefresh = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  conversationId: conv['id'] ?? 0,
                                  senderId: myCurrentUserId,
                                  receiverId: targetUserId,
                                  token: widget.accessToken,
                                  sellerName:
                                      conv['sellerName']?.toString() ??
                                      "Người bán",
                                  isSellerMode: widget.isSellerMode,
                                  product: {
                                    'id': conv['productSellerId'] ?? 0,
                                    'productName':
                                        conv['productName']?.toString() ??
                                        'Sản phẩm',
                                    'avatar': conv['productImageUrl']
                                        ?.toString(),
                                    'price':
                                        (conv['price'] as num?)?.toDouble() ??
                                        0.0,
                                    'description':
                                        conv['description']?.toString() ??
                                        "thông tin ở trang chi tiết sản phẩm",
                                    'sellerName':
                                        conv['sellerName']?.toString() ??
                                        "Người bán",
                                    'sellerEmail':
                                        conv['sellerEmail']?.toString() ??
                                        "Chưa có email",
                                  },
                                ),
                              ),
                            );

                            if (shouldRefresh == true) {
                              _loadConversations();
                            }
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: const Row(
        children: [
          Text("Danh sách hội thoại", style: FruitColors.topBarTitle),
          Spacer(),
          Icon(Icons.chat_bubble, color: FruitColors.primaryGreen, size: 22),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int conversationId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xóa hội thoại"),
        content: const Text("Bạn có chắc chắn muốn xóa hội thoại này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await deleteConversation(conversationId);
      _loadConversations();
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    if (conversationId <= 0) return;

    try {
      final response = await http.delete(
        Uri.parse(
          '${AppConfig.baseUrl}/api/v1/chat/conversation/$conversationId',
        ),
        headers: {'Authorization': 'Bearer ${widget.accessToken}'},
      );

      if (response.statusCode == 200 || response.statusCode == 404) {
        if (mounted) {
          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đã xóa hội thoại!"),
                backgroundColor: Colors.green,
              ),
            );
          }
          _loadConversations();
        }
      } else {
        throw Exception("Server trả về lỗi: ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Lỗi xóa hội thoại (có thể đã xóa rồi): $e");
    }
  }
}
