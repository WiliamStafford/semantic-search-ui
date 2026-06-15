class CartResponse {
  final int cartId;
  final List<CartItem> items;
  final double totalPrice;

  CartResponse({required this.cartId, required this.items, required this.totalPrice});

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cartId: json['cartId'],
      items: (json['items'] as List).map((i) => CartItem.fromJson(i)).toList(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );
  }
}

class CartItem {
  final int id;
  final int sellerProductId;
  final int quantity;
  final String productName;
  final double price;
  final String imageUrl;
  final int sellerId;

  CartItem({
    required this.id,
    required this.sellerProductId,
    required this.quantity,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.sellerId
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      sellerProductId: json['sellerProductId'],
      quantity: json['quantity'],
      productName: json['productName'] ?? 'Sản phẩm không có tên',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] ?? '',
      sellerId: json['sellerId'] ?? 3,
    );
  }
}