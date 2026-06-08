import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../theme/fruit_colors.dart';

class SellerReturnScreen extends StatefulWidget {
  final String accessToken;
  const SellerReturnScreen({super.key, required this.accessToken});

  @override
  State<SellerReturnScreen> createState() => _SellerReturnScreenState();
}

class _SellerReturnScreenState extends State<SellerReturnScreen> {
  String get _cleanToken => widget.accessToken.trim().replaceAll(RegExp(r'[\r\n\t]+'), '');
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải lại dữ liệu và cập nhật UI
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    _requests = await _fetchRequests();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<List<dynamic>> _fetchRequests() async {
    try {
      final res = await http.get(
        Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/returns/with-proof'),
        headers: {'Authorization': 'Bearer $_cleanToken', 'Accept': 'application/json', 'ngrok-skip-browser-warning': 'true'},
      );
      if (res.statusCode == 200) {
        final body = utf8.decode(res.bodyBytes).trim();
        return jsonDecode(body.startsWith('[') ? body : '[]');
      }
    } catch (e) { debugPrint("Lỗi fetch: $e"); }
    return [];
  }

  Future<String?> _uploadImageToBackend(int requestId, XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      var request = http.MultipartRequest('POST',
          Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/returns/$requestId/upload-refund-proof'));
      request.headers['Authorization'] = 'Bearer $_cleanToken';
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: image.name));
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr)['url'];
      }
    } catch (e) { debugPrint("Lỗi upload: $e"); }
    return null;
  }

  Future<void> _updateStatus(int requestId, String status, String note, String? proofUrl) async {
    final res = await http.put(
      Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/returns/$requestId/status'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_cleanToken', 'ngrok-skip-browser-warning': 'true'},
      body: jsonEncode({'status': status, 'note': note, 'refundProofUrl': proofUrl}),
    );

    if (res.statusCode == 200 && mounted) {
      await _loadData(); // Tự động làm mới UI sau khi duyệt
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Duyệt đơn thành công!")));
    }
  }

  void _showReasonDialog(int requestId, String status) {
    final TextEditingController noteController = TextEditingController();
    final TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // StatefulBuilder là BẮT BUỘC để update UI trong Dialog
        builder: (context, setDialogState) => AlertDialog(
          title: Text(status == 'APPROVED' ? "Duyệt hoàn tiền" : "Từ chối khiếu nại"),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 100,
                  child: TextField(
                    controller: noteController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: "Ghi chú xử lý", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      // Cập nhật text trong Dialog bằng setDialogState
                      setDialogState(() { linkController.text = "Đang tải ảnh..."; });

                      String? url = await _uploadImageToBackend(requestId, image);

                      // Cập nhật kết quả vào ô nhập liệu
                      setDialogState(() { linkController.text = url ?? "Lỗi upload!"; });
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Chọn ảnh minh chứng"),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: TextField(
                    controller: linkController,
                    maxLines: 1,
                    decoration: const InputDecoration(labelText: "URL ảnh thanh toán", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _updateStatus(requestId, status, noteController.text.trim(), linkController.text.trim());
              },
              child: const Text("Xác nhận"),
            ),
          ],
        ),
      ),
    );
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
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, i) {
                final item = _requests[i];
                return Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Text("Yêu cầu #${item['id']}", style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(width: 8), _buildStatusChip(item['status'])]),
                      const Divider(),
                      Text("Lý do: ${item['returnReason']}"),
                      const SizedBox(height: 10),
                      const Text("Minh chứng:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _buildSafeImage(item['evidenceImageUrls']),
                        if (item['status'] == 'APPROVED') ...[const SizedBox(width: 10), _buildSafeImage(item['sellerRefundProofUrl'])],
                      ]),
                      if (item['status'] == 'PENDING') Padding(padding: const EdgeInsets.only(top: 16), child: Row(children: [
                        Expanded(child: _buildActionButton("Từ chối", Colors.red, Icons.close, () => _showReasonDialog(item['id'], "REJECTED"))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton("Duyệt đơn", Colors.green, Icons.check, () => _showReasonDialog(item['id'], "APPROVED"))),
                      ])),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeImage(dynamic data) {
    String url = data?.toString().trim() ?? "";

    return SizedBox(
      width: 200, height: 100,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (url.isNotEmpty && url.startsWith('http'))
              ? Image.network(
            url,
            fit: BoxFit.cover,
            headers: const {"Access-Control-Allow-Origin": "*"},
          )
              : const Center(child: Icon(Icons.image, color: Colors.grey)),
        ),
      ),
    );
  }

  Widget _buildTopBar() => Container(color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), child: const Row(children: [Icon(Icons.assignment_return_outlined, color: FruitColors.primaryGreen), SizedBox(width: 8), Text("Quản Lý Khiếu Nại", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen))]));
  Widget _buildStatusChip(String status) { Color color = status == 'PENDING' ? Colors.orange : (status == 'APPROVED' ? Colors.green : Colors.red); return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))); }
  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onPressed) => ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: onPressed, icon: Icon(icon, size: 18), label: Text(label));
}