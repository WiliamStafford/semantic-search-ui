class TopProductResponse {
  final String productName;
  final int totalSold;
  final double totalRevenue;

  TopProductResponse({
    required this.productName,
    required this.totalSold,
    required this.totalRevenue,
  });

  factory TopProductResponse.fromJson(Map<String, dynamic> json) =>
      TopProductResponse(
        productName: json['productName'],
        totalSold: (json['totalSold'] as num).toInt(),
        totalRevenue: (json['totalRevenue'] as num).toDouble(),
      );
}
