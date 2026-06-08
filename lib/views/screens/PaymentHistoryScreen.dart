import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../core/utils/format_utils.dart';
import '../theme/fruit_colors.dart';
import '../../data/datasource/user_remote_data_source.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String accessToken;

  const PaymentHistoryScreen({super.key, required this.accessToken});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late Future<List<dynamic>> _paymentsFuture;
  int? _userId;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserAndPayments();
  }

  Future<void> _fetchUserAndPayments() async {
    try {
      final userProfile = await UserRemoteDataSource().getUserProfile(widget.accessToken);
      if (mounted) {
        setState(() {
          _userId = userProfile.id;
          _isLoadingUser = false;
          _paymentsFuture = _fetchPayments(userProfile.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
      }
    }
  }

  Future<List<dynamic>> _fetchPayments(int userId) async {
    final response = await http.get(
      Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/payments/user/$userId'),
      headers: {
        'Authorization': 'Bearer ${widget.accessToken}',
        'ngrok-skip-browser-warning': 'any',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Không thể tải lịch sử thanh toán');
    }
  }

  Future<void> _handleRefresh() async {
    if (_userId != null) {
      setState(() {
        _paymentsFuture = _fetchPayments(_userId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: FruitColors.accentGreen)),
      );
    }

    // 🌟 FIXED: Loại bỏ hoàn toàn bọc Row và SharedSidebar lồng gây vỡ layout
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: _userId == null
                ? _buildErrorState("Không thể xác định danh tính người dùng.")
                : FutureBuilder<List<dynamic>>(
              future: _paymentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen));
                } else if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }
                final payments = snapshot.data ?? [];
                if (payments.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  color: FruitColors.primaryGreen,
                  onRefresh: _handleRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(32),
                    itemCount: payments.length,
                    itemBuilder: (context, index) => _buildPaymentCard(payments[index]),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: const Row(
        children: [
          Text("Lịch sử giao dịch thanh toán",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen)),
          Spacer(),
          Icon(Icons.payment, color: FruitColors.accentGreen),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment) {
    String transactionId = payment['transactionId'] ?? 'N/A';
    int orderId = payment['orderId'] ?? 0;
    String provider = payment['provider'] ?? 'PAYPAL'; // PAYPAL hoặc VNPAY
    double amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;

    String rawDate = payment['paymentDate'] ?? DateTime.now().toIso8601String();
    DateTime parsedDate = DateTime.parse(rawDate);

    String formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(parsedDate);

    String status = payment['status'] ?? 'SUCCESS';
    bool isSuccess = status == 'SUCCESS' || status == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: provider == 'PAYPAL' ? Colors.blue[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              provider == 'PAYPAL' ? Icons.account_balance_wallet : Icons.credit_card,
              color: provider == 'PAYPAL' ? Colors.blue[800] : Colors.red[800],
              size: 28,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider == 'PAYPAL' ? "Thanh toán qua PayPal" : "Thanh toán qua VNPAY",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text("Mã đơn hàng: #$orderId", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                Text("Mã giao dịch: $transactionId", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text("Thời gian: $formattedDate", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${FormatUtils.vnCurrency.format(amount)}",
                style: TextStyle(
                  color: isSuccess ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSuccess ? "THÀNH CÔNG" : "THẤT BẠI",
                  style: TextStyle(
                    color: isSuccess ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card_off_outlined, size: 80, color: FruitColors.softGreen.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("Bạn chưa thực hiện giao dịch online nào.", style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text("Lỗi: $error", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}