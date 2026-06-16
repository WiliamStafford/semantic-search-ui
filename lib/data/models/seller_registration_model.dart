class SellerRegistration {
  final int id;
  final int userId;
  final String shopName;
  final String address;
  final String description;
  final String status;


  SellerRegistration({
    required this.id,
  required this.userId,
    required this.shopName,
    required this.address,
    required this.description,
    required this.status
  });

  factory SellerRegistration.fromJson(Map<String, dynamic> json) {
    return SellerRegistration(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: int.tryParse(json['userId']?.toString() ?? '0') ?? 0,
      shopName: json['shopName']?.toString() ?? 'Chưa cập nhật',
      address: json['address']?.toString() ?? 'Chưa cập nhật',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
    );
  }
}