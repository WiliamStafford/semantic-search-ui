class SellerDashboardModel {
  final double totalRevenue;
  final int totalOrders;
  final int lowStockProducts;
  final List<SellerProductItem> productsList;

  SellerDashboardModel({
    required this.totalRevenue,
    required this.totalOrders,
    required this.lowStockProducts,
    required this.productsList,
  });

  factory SellerDashboardModel.fromJson(Map<String, dynamic> json) {
    return SellerDashboardModel(
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] ?? 0,
      lowStockProducts: json['lowStockProducts'] ?? 0,
      productsList: (json['productsList'] as List? ?? [])
          .map((item) => SellerProductItem.fromJson(item))
          .toList(),
    );
  }
}

class SellerProductItem {
  final int id;
  final String name;       // Khớp trường 'name' của SellerProduct Backend
  final double price;
  final int stock;
  final String sku;
  final String? imageUrl;  // Khớp trường 'imageUrl' của SellerProduct Backend
  final String status;

  // 🌟 ĐÃ THÊM: 2 trường dữ liệu mới để khớp với Database
  final String? description;
  final String unit;

  SellerProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.sku,
    this.imageUrl,
    required this.status,
    this.description,
    this.unit = 'kg', // Mặc định an toàn là kg
  });

  // Giữ nguyên các getter của bạn
  String get productName => name;
  String? get avatar => imageUrl;

  // 🌟 Cầu nối để code UI gọi item.productId không bị lỗi
  int get productId => id;

  factory SellerProductItem.fromJson(Map<String, dynamic> json) {
    return SellerProductItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Nông sản chưa đặt tên',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] ?? 0,
      sku: json['sku'] ?? 'N/A',
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'ACTIVE',

      description: json['description'],
      unit: json['unit'] ?? 'kg',
    );
  }
}