class ProductModel {
  final int id;
  final int sellerProductId;
  final String productName;
  final String? avatar;
  final double price;
  final double averageRating;
  final bool isFavorite;
  final int stock;

  ProductModel({
    required this.id,
    required this.sellerProductId,
    required this.productName,
    this.avatar,
    required this.price,
    this.averageRating = 0.0,
    this.isFavorite = false,
    required this.stock,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      sellerProductId: json['sellerProductId'] ?? 0,
      stock: json['stock'] ?? 0,
      productName: json['productName'] ?? '',
      avatar: json['avatar'],
      price: (json['price'] as num? ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] as num? ?? 0.0).toDouble(),
      isFavorite: json['isFavorite'] ?? false,
      id: json['productId'] ?? 0,
    );
  }
}