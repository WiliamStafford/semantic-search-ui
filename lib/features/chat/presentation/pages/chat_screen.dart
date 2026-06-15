import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../../../../config/app_config.dart';
import '../../data/datasource/chat_websocket_service.dart';
import 'package:semantic_search_ui/views/theme/fruit_colors.dart';
import 'package:semantic_search_ui/core/utils/format_utils.dart';
import '../../data/datasource/chat_api_service.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId, senderId, receiverId;
  final String token;
  final String sellerName;
  final Map<String, dynamic> product;
  final bool isSellerMode;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.token,
    required this.sellerName,
    required this.product,
    this.isSellerMode = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatWebSocketService _chatService;
  List<Map<String, dynamic>> _messages = [];

  final cloudinary = CloudinaryPublic('your_cloud_name', 'your_upload_preset');

  @override
  void initState() {
    super.initState();

    _loadHistory();
    _chatService = ChatWebSocketService(
      conversationId: widget.conversationId.toString(),
      onMessageReceived: (msg) {
        if (!mounted) return;
        setState(() {
          if (!_messages.any((m) => m['id'] == msg['id'])) {
            _messages.add(msg);
          }
        });
        _scrollToBottom();
      },
    );

    _chatService.connect(widget.token);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _uploadAndSend(dynamic file) async {
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      _sendCustomMessage(response.secureUrl, type: 'image');
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi upload: $e")));
    }
  }


  void _sendCustomMessage(String content, {String type = 'text'}) {
    if (content.trim().isEmpty) return;
    final int productSellerId = widget.product['id'] ?? 0;

    _chatService.sendMessage(
      content,
      widget.senderId,
      widget.receiverId,
      productSellerId,
      type: type,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) => _uploadAndSend(details.files.first),
      child: Scaffold(
        backgroundColor: FruitColors.background,
        appBar: AppBar(
          backgroundColor: FruitColors.primaryGreen,
          title: Text(
            widget.isSellerMode ? "Chat với Khách hàng" : "Chat với Người bán",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w400,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: const Color(0xFFE0E0E0),
              offset: const Offset(0, 50),
              onSelected: (value) async {
                if (value == 'delete') {
                  await deleteConversation(widget.conversationId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Color(0xFFB71C1C), size: 22),
                      // Icon đỏ trầm
                      SizedBox(width: 12),
                      Text(
                        "Xóa hội thoại",
                        style: TextStyle(
                          color: Color(0xFF263238),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CỘT BÊN TRÁI: Thông tin sản phẩm
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ảnh sản phẩm (Giữ nguyên)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child:
                              (widget.product['avatar'] != null &&
                                  widget.product['avatar']
                                      .toString()
                                      .startsWith('http'))
                              ? Image.network(
                                  widget.product['avatar'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.broken_image,
                                          color: Colors.red,
                                        ),
                                      ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 40),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tên sản phẩm
                      Text(
                        widget.product['productName'] ?? 'Sản phẩm',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Giá sản phẩm
                      Text(
                        FormatUtils.vnCurrency.format(
                          widget.product['price'] ?? 0,
                        ),
                        style: const TextStyle(
                          color: FruitColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Divider(height: 24),

                      // Mô tả sản phẩm và Thông tin người bán
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Mô tả:",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.product['description'] ??
                                    "thông tin ở trang chi tiết sản phẩm",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.5,
                                ),
                              ),

                              const Divider(height: 32),

                              Text(
                                widget.isSellerMode ?  "Người bán:":"Người bán:" ,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.sellerName ?? "Đối phương",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: FruitColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CỘT BÊN PHẢI: Khung chat
              Expanded(
                flex: 7,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: //
                        ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(10),
                          itemCount: _messages.length,
                          itemBuilder: (context, i) {
                            final msg = _messages[i];

                            bool isMe = msg['senderId'] == widget.senderId;
                            bool isImg = msg['type'] == 'image';

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? FruitColors.primaryGreen
                                      : FruitColors.cardBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isMe
                                      ? null
                                      : Border.all(
                                          color: FruitColors.lightGreen,
                                        ),
                                ),
                                child: isImg
                                    ? Image.network(msg['content'], width: 200)
                                    : Text(
                                        msg['content'] ?? "",
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Thanh nhập liệu
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.image,
                                color: FruitColors.primaryGreen,
                              ),
                              onPressed: () async {
                                final XFile? img = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (img != null) _uploadAndSend(img);
                              },
                            ),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  hintText: "Nhập tin nhắn...",
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: FruitColors.primaryGreen,
                              ),
                              onPressed: () =>
                                  _sendCustomMessage(_controller.text),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadHistory() async {
    final res = await http.get(
      Uri.parse(
        '${AppConfig.baseUrl}/api/v1/chat/history/${widget.conversationId}',
      ),
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (res.statusCode == 200 && mounted) {
      setState(
        () => _messages = json
            .decode(utf8.decode(res.bodyBytes))
            .cast<Map<String, dynamic>>(),
      );
      _scrollToBottom();
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    if (conversationId <= 0) return;

    try {
      final response = await http.delete(
        Uri.parse(
          '${AppConfig.baseUrl}/api/v1/chat/conversation/$conversationId',
        ),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 404) {
        if (mounted) {
          // Nếu là 200 hoặc 204, báo thành công
          if (response.statusCode == 200 || response.statusCode == 204) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Đã xóa hội thoại!"),
                backgroundColor: Colors.green,
              ),
            );
          }
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("Server trả về lỗi: ${response.statusCode}");
      }
    } catch (e) {
      print("DEBUG: Lỗi xóa hội thoại: $e");
    }
  }
  @override
  void dispose() {
    _chatService.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
