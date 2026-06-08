import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../theme/fruit_colors.dart';
import '../../data/models/seller_dashboard_model.dart';
import '../../data/datasource/SellerRemoteDataSource.dart';
import '../widgets/product_image_picker.dart';

class SellerDashboardScreen extends StatefulWidget {
  final String accessToken;
  const SellerDashboardScreen({super.key, required this.accessToken});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  List<Map<String, dynamic>> _categoryList = [];
  int? _selectedCategoryId;
  late Future<SellerDashboardModel> _dashboardFuture;

  final List<String> unitList = ['kg', 'gram', 'trái', 'quả', 'chùm', 'bó', 'thùng', 'hộp', 'túi'];

  @override
  void initState() {
    super.initState();
    _dashboardFuture = SellerRemoteDataSource().getDashboardData(widget.accessToken);
    _fetchCategories();
  }
  Future<void> _fetchCategories() async {
    try {
      final url = 'https://napping-squash-majorette.ngrok-free.dev/api/v1/categories';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Accept': 'application/json',
          'ngrok-skip-browser-warning': 'true', // 🌟 Dòng này sẽ xóa bỏ trang cảnh báo của Ngrok
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _categoryList = data.map((e) => {"id": e['id'], "name": e['name']}).toList();
        });
        debugPrint("Đã tải được ${_categoryList.length} danh mục");
      }
    } catch (e) {
      debugPrint("Lỗi tải danh mục: $e");
    }
  }

  Future<void> _triggerSync() async {
    try {
      final response = await http.post(
        Uri.parse('https://napping-squash-majorette.ngrok-free.dev/api/v1/migration/sync'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
        },
      );
      if (response.statusCode == 200) {
        debugPrint("Đồng bộ dữ liệu thành công!");
      }
    } catch (e) {
      debugPrint("Lỗi gọi sync: $e");
    }
  }

  void _showDeleteConfirmation(BuildContext context, int productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Xác nhận xóa", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text("Bạn có chắc chắn muốn xóa nông sản này không? Hành động này không thể hoàn tác và sẽ gỡ sản phẩm khỏi hệ thống tìm kiếm."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY BỎ", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              bool success = await SellerRemoteDataSource().deleteProduct(widget.accessToken, productId);

              if (success && context.mounted) {
                await _triggerSync();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa sản phẩm thành công!")));
                setState(() {
                  _dashboardFuture = SellerRemoteDataSource().getDashboardData(widget.accessToken);
                });
              } else if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Xóa thất bại! Vui lòng kiểm tra lại đơn hàng liên quan.")));
              }
            },
            child: const Text("XÓA NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, SellerProductItem item) {
    final nameController = TextEditingController(text: item.productName);
    final priceController = TextEditingController(text: item.price.toString());
    final stockController = TextEditingController(text: item.stock.toString());
    final descController = TextEditingController(text: item.description ?? "");

    String selectedUnit = unitList.contains(item.unit) ? item.unit : 'kg';

    String tempImageUrl = item.avatar ?? "";
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Chỉnh sửa nông sản", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên nông sản")),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá bán")),
                  TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số lượng kho")),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: "Đơn vị tính", border: OutlineInputBorder()),
                    items: unitList.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setDialogState(() {
                        selectedUnit = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Ghi chú / Mô tả sản phẩm",
                      hintText: "Cập nhật lại mô tả chi tiết nông sản...",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text("Cập nhật ảnh:", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  ProductImagePicker(onUploadSuccess: (url) => setDialogState(() => tempImageUrl = url)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FruitColors.primaryGreen),
              onPressed: _isSaving ? null : () async {
                setDialogState(() => _isSaving = true);
                final updatedData = {
                  "productId": item.id,
                  "name": nameController.text.trim(),
                  "price": double.tryParse(priceController.text) ?? 0,
                  "stock": int.tryParse(stockController.text) ?? 0,
                  "description": descController.text.trim(),
                  "unit": selectedUnit,
                  "imageUrl": tempImageUrl,
                };

                bool success = await SellerRemoteDataSource().updateProduct(widget.accessToken, updatedData);

                if (success && context.mounted) {
                  await _triggerSync();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
                  setState(() {
                    _dashboardFuture = SellerRemoteDataSource().getDashboardData(widget.accessToken);
                  });
                } else if (context.mounted) {
                  setDialogState(() => _isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra khi cập nhật sản phẩm!")));
                }
              },
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("LƯU THAY ĐỔI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descController = TextEditingController();

    String selectedUnit = 'kg';
    int? selectedCategoryId;
    String tempImageUrl = "";
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.add_business, color: FruitColors.primaryGreen),
              SizedBox(width: 10),
              Text("Đăng Bán Nông Sản Mới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Tên nông sản (Ví dụ: Táo đá Hà Giang)")),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: _categoryList.isEmpty ? "Đang tải danh mục..." : "Danh mục chức năng",
                      border: const OutlineInputBorder(),
                    ),
                    value: selectedCategoryId,
                    items: _categoryList.map((cat) => DropdownMenuItem<int>(
                      value: cat['id'] as int,
                      child: Text(cat['name'] as String),
                    )).toList(),
                    onChanged: _categoryList.isEmpty
                        ? null
                        : (val) => setDialogState(() => selectedCategoryId = val),
                  ),

                  const SizedBox(height: 16),
                  TextField(controller: priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Giá bán (VNĐ)")),
                  TextField(controller: stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Số lượng nhập kho")),

                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    decoration: const InputDecoration(labelText: "Đơn vị tính", border: OutlineInputBorder()),
                    items: unitList.map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) => setDialogState(() => selectedUnit = newValue!),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Ghi chú / Mô tả sản phẩm",
                      hintText: "Nhập mô tả chi tiết nông sản...",
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Align(alignment: Alignment.centerLeft, child: Text("Hình ảnh:", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),

                  ProductImagePicker(
                    onUploadSuccess: (url) => setDialogState(() => tempImageUrl = url),
                  ),

                  if (tempImageUrl.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(" Đã tải ảnh lên thành công!", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("HỦY BỎ", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: FruitColors.primaryGreen),
              onPressed: (_isSaving || selectedCategoryId == null || tempImageUrl.isEmpty) ? null : () async {
                setDialogState(() => _isSaving = true);

                final productData = {
                  "name": nameController.text.trim(),
                  "price": double.tryParse(priceController.text) ?? 0,
                  "stock": int.tryParse(stockController.text) ?? 0,
                  "categoryId": selectedCategoryId,
                  "description": descController.text.trim(),
                  "unit": selectedUnit,
                  "imageUrl": tempImageUrl,
                };

                bool success = await SellerRemoteDataSource().addProduct(widget.accessToken, productData);

                if (success && context.mounted) {
                  await _triggerSync();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng bán nông sản thành công!")));
                  setState(() {
                    _dashboardFuture = SellerRemoteDataSource().getDashboardData(widget.accessToken);
                  });
                } else if (context.mounted) {
                  setDialogState(() => _isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi hệ thống: Vui lòng kiểm tra lại kết nối!")));
                }
              },
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("ĐĂNG BÁN NGAY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FruitColors.background,
      body: FutureBuilder<SellerDashboardModel>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: FruitColors.accentGreen));
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Đang đợi kết nối API thật từ Backend... (Chi tiết: ${snapshot.error})",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(32),
                  children: [
                    _buildWelcomeBanner(),
                    const SizedBox(height: 24),

                    GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.0,
                      children: [
                        _statCard("TỔNG DOANH THU", "${NumberFormat('#,###').format(data.totalRevenue)}đ", Icons.monetization_on, Colors.green),
                        _statCard("ĐƠN HÀNG HỆ THỐNG", "${data.totalOrders} đơn", Icons.local_shipping, Colors.blue),
                        _statCard("NÔNG SẢN CẢNH BÁO KHO", "${data.lowStockProducts} mặt hàng", Icons.warning_amber_rounded, Colors.orange),
                      ],
                    ),

                    const SizedBox(height: 32),
                    _buildRealProductsSection(data.productsList),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: const Row(
        children: [
          Icon(Icons.storefront, color: FruitColors.primaryGreen, size: 24),
          SizedBox(width: 8),
          Text(
            "Kênh Quản Lý Người Bán (Seller Studio)",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: FruitColors.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [FruitColors.primaryGreen, FruitColors.accentGreen]),
          borderRadius: BorderRadius.circular(12)
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chào mừng trở lại, Chủ gian hàng! 👋", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text("Hệ thống đã sẵn sàng đồng bộ dữ liệu real-time với hệ thống thực thể Spring Boot.", style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(icon, color: color.withOpacity(0.8), size: 36),
        ],
      ),
    );
  }

  Widget _buildRealProductsSection(List<SellerProductItem> products) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                  "Danh mục hàng hóa thực tế trong kho (Seller Products)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: FruitColors.primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                onPressed: () => _showAddProductDialog(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: const Text("THÊM NÔNG SẢN", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 20),

          Table(
            border: TableBorder(bottom: BorderSide(color: Colors.grey.shade100)),
            columnWidths: const {
              0: FlexColumnWidth(0.8),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(3.0),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(1.5),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade50),
                children: const [
                  Padding(padding: EdgeInsets.all(12), child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text("Hình ảnh", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text("Tên sản phẩm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text("Giá bán", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text("Số lượng kho", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                  Padding(padding: EdgeInsets.all(12), child: Text("Thao tác", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                ],
              ),

              ...products.map((item) => TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(16), child: Text("${item.id}", style: const TextStyle(fontSize: 13, color: Colors.grey))),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: item.avatar != null && item.avatar!.isNotEmpty
                          ? Image.network(item.avatar!, width: 40, height: 40, fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(width: 40, height: 40, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, size: 18, color: Colors.grey)))
                          : Container(width: 40, height: 40, color: Colors.green.shade50, child: const Icon(Icons.eco, size: 18, color: FruitColors.primaryGreen)),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                  ),
                  Padding(padding: const EdgeInsets.all(16), child: Text("${NumberFormat('#,###').format(item.price)}", style: const TextStyle(fontSize: 13, color: FruitColors.accentGreen, fontWeight: FontWeight.bold))),

                  // 🌟 SỬA: Hiển thị Đơn vị tính lấy từ Backend thay vì fix cứng "kg"
                  Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                          "${item.stock} ${item.unit}",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: item.stock <= 5 ? FontWeight.bold : FontWeight.normal,
                              color: item.stock <= 5 ? Colors.red : Colors.black54
                          )
                      )
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: FruitColors.primaryGreen, size: 20),
                          onPressed: () => _showEditProductDialog(context, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => _showDeleteConfirmation(context, item.id),
                        ),
                      ],
                    ),
                  ),
                ],
              )).toList(),
            ],
          ),
        ],
      ),
    );
  }
}
