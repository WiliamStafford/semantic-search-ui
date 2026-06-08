import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/fruit_colors.dart';

class ReviewsScreen extends StatefulWidget {
  final String accessToken;
  const ReviewsScreen({super.key, required this.accessToken});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  late Future<List<dynamic>> _reviewsFuture;

  @override
  void initState() {
    super.initState();
    _reviewsFuture = _fetchMyReviews();
  }

  Future<List<dynamic>> _fetchMyReviews() async {
    final res = await http.get(
      Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/reviews/my-reviews'),
      headers: {'Authorization': 'Bearer ${widget.accessToken}', 'ngrok-skip-browser-warning': 'any'},
    );
    if (res.statusCode == 200) return jsonDecode(utf8.decode(res.bodyBytes));
    throw Exception("Lỗi tải đánh giá");
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 KHÓA LỖI: Lột bỏ hoàn toàn cấu trúc Row + SharedSidebar cũ
    // Trả về trực tiếp nội dung chính để MainLayoutScreen lồng ghép mượt mà
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _reviewsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: FruitColors.accentGreen),
                  );
                }
                final reviews = snapshot.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(child: Text("Hùng chưa viết đánh giá nào."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
                );
              },
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
          Text(
            "Đánh giá của tôi",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen),
          ),
          Spacer(),
          Icon(Icons.star, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    String date = DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.parse(review['createdAt']));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Sản phẩm: #${review['productId']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) => Icon(
              i < (review['rating'] ?? 5) ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            )),
          ),
          const SizedBox(height: 8),
          Text(review['comment'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}