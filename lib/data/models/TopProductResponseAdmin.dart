class TopProductResponseAdmin {
  final int productId;
  final String productName;
  final int totalSold;
  final double totalRevenue;

  TopProductResponseAdmin({
    required this.productId,
    required this.productName,
    required this.totalSold,
    required this.totalRevenue,
  });

  factory TopProductResponseAdmin.fromJson(Map<String, dynamic> json) {
    return TopProductResponseAdmin(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] ?? "Unknown",
      totalSold: (json['totalSold'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}