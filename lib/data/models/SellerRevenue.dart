class SellerRevenue {
  final int sellerId;
  final double totalRevenue;
  final int totalOrders;

  SellerRevenue({required this.sellerId, required this.totalRevenue, required this.totalOrders});

  factory SellerRevenue.fromJson(Map<String, dynamic> json) {
    return SellerRevenue(
      sellerId: json['sellerId'],
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      totalOrders: json['totalOrders'],
    );
  }
}