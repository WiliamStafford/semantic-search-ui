import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../core/utils/format_utils.dart';
import '../theme/fruit_colors.dart';

class SemanticSearchScreen extends StatefulWidget {
  final String accessToken;
  const SemanticSearchScreen({super.key, required this.accessToken});

  @override
  State<SemanticSearchScreen> createState() => _SemanticSearchScreenState();
}

class _SemanticSearchScreenState extends State<SemanticSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  double _similarityThreshold = 0.70;

  Future<void> _executeSemanticSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
    });

    try {
      final response = await http.get(
        Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/products/semantic-search?q=${Uri.encodeComponent(query)}&page=0&size=20'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'ngrok-skip-browser-warning': 'any',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _searchResults = data['content'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Lỗi máy chủ: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối đến hệ thống AI: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildSearchBar(),        // Đã khôi phục
          _buildThresholdSlider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen))
                : _errorMessage.isNotEmpty
                ? _buildCenterMessage(_errorMessage, Icons.error_outline, Colors.red)
                : _searchResults.isEmpty
                ? _buildCenterMessage("Nhập từ khóa ngữ nghĩa để AI tìm kiếm sản phẩm...", Icons.psychology_outlined, FruitColors.primaryGreen)
                : _buildFilteredGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Ví dụ: 'Trái cây giải nhiệt mùa hè nóng bức'...",
                prefixIcon: const Icon(Icons.auto_awesome, color: FruitColors.accentGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: _executeSemanticSearch,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => _executeSemanticSearch(_searchController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: FruitColors.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text("TÌM KIẾM AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSlider() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Độ tương đồng tối thiểu:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("${(_similarityThreshold * 100).toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
            ],
          ),
          Slider(
            value: _similarityThreshold,
            min: 0.45,
            max: 0.90,
            divisions: 9,
            activeColor: FruitColors.primaryGreen,
            onChanged: (val) => setState(() => _similarityThreshold = val),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredGrid() {
    final filtered = _searchResults.where((item) => (item['score'] ?? 0.0) >= _similarityThreshold).toList();
    if (filtered.isEmpty) return _buildCenterMessage("Không có sản phẩm đạt ngưỡng này.", Icons.filter_alt_off, Colors.orange);

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.75,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final product = item['product'];
        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: product['imageUrl'] != null ? DecorationImage(image: NetworkImage(product['imageUrl']), fit: BoxFit.cover) : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                    Text("${((item['score'] ?? 0.0) * 100).toStringAsFixed(1)}% Match", style: const TextStyle(color: FruitColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text("${FormatUtils.vnCurrency.format(product['price'] ?? 0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterMessage(String msg, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}