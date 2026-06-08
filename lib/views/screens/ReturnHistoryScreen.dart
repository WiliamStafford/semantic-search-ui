import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/fruit_colors.dart';
import '../../data/datasource/user_remote_data_source.dart';

class ReturnHistoryScreen extends StatefulWidget {
  final String accessToken;
  final int userId;

  const ReturnHistoryScreen({
    super.key,
    required this.accessToken,
    required this.userId,
  });

  @override
  State<ReturnHistoryScreen> createState() => _ReturnHistoryScreenState();
}

class _ReturnHistoryScreenState extends State<ReturnHistoryScreen> {
  List<dynamic> _returnRequests = [];
  bool _isLoading = true;
  String _errorMessage = '';

  int? _resolvedUserId;

  @override
  void initState() {
    super.initState();
    _fetchMyReturnRequests();
  }

  Future<void> _fetchMyReturnRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_resolvedUserId == null) {
        if (widget.userId != 0) {
          _resolvedUserId = widget.userId;
        } else {
          final userProfile = await UserRemoteDataSource().getUserProfile(widget.accessToken);
          _resolvedUserId = userProfile.id;
        }
      }

      final response = await http.get(
        Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/returns/my-requests/$_resolvedUserId'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'ngrok-skip-browser-warning': 'any',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _returnRequests = jsonDecode(utf8.decode(response.bodyBytes));
          _isLoading = false;
        });
      } else if (response.statusCode == 204) {
        setState(() {
          _returnRequests = [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Không thể tải danh sách khiếu nại (Mã lỗi: ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối máy chủ Backend: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String label;

    switch (status) {
      case 'APPROVED':
        chipColor = Colors.green;
        label = 'Đã duyệt hoàn tiền';
        break;
      case 'REJECTED':
        chipColor = Colors.redAccent;
        label = 'Bị từ chối';
        break;
      default:
        chipColor = Colors.orange;
        label = 'Chờ đối soát';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: chipColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReturnCard(dynamic request) {
    String status = request['status'] ?? 'PENDING';
    String reason = request['returnReason'] ?? '';
    String adminNote = request['note'] ?? '';
    String refundMethod = request['refundMethod'] ?? 'BANK_TRANSFER';

    String rawEvidence = request['evidenceImageUrls'] ?? '';
    List<String> evidenceImages = rawEvidence.isNotEmpty ? rawEvidence.split(',') : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Mã yêu cầu: #REQ-${request['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              _buildStatusChip(status),
            ],
          ),
          const SizedBox(height: 6),
          Text("📦 Mã dòng sản phẩm: #ITEM-${request['orderItemId']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Divider(height: 20),

          const Text("Lý do khiếu nại của bạn:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(reason, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: FruitColors.background, borderRadius: BorderRadius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  " Nơi nhận tiền: ${refundMethod == 'BANK_TRANSFER' ? 'Chuyển khoản Ngân hàng' : 'Ví quốc tế PayPal'}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                if (refundMethod == 'BANK_TRANSFER') ...[
                  Text("Ngân hàng: ${request['bankName'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text("Số tài khoản: ${request['bankAccountNumber'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text("Chủ tài khoản: ${request['bankAccountName'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ] else ...[
                  Text("Email PayPal: ${request['paypalEmail'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (evidenceImages.isNotEmpty) ...[
            const Text("Hình ảnh minh chứng gửi kèm:", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: evidenceImages.length,
                itemBuilder: (context, i) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 64,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.grey.withOpacity(0.06))),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(evidenceImages[i], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withOpacity(0.1))),
              child: Text("💬 Phản hồi từ Hệ thống: $adminNote", style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontStyle: FontStyle.italic)),
            )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildTopHeaderBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen))
                : _errorMessage.isNotEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 44),
                    const SizedBox(height: 12),
                    Text(_errorMessage, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _fetchMyReturnRequests, child: const Text("Thử lại")),
                  ],
                ),
              ),
            )
                : RefreshIndicator(
              color: FruitColors.accentGreen,
              onRefresh: _fetchMyReturnRequests,
              child: _returnRequests.isEmpty
                  ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text("Bạn chưa có đơn khiếu nại đổi trả nào.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _returnRequests.length,
                itemBuilder: (context, index) => _buildReturnCard(_returnRequests[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: const Row(
        children: [
          Text(
            "Lịch Sử Đổi Trả / Khiếu Nại",
            style: TextStyle(color: FruitColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Spacer(),
          Icon(Icons.assignment_return_outlined, color: FruitColors.primaryGreen),
        ],
      ),
    );
  }
}