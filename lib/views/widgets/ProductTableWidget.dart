import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/seller_dashboard_model.dart';
import '../theme/fruit_colors.dart';

class ProductTableWidget extends StatelessWidget {
  final List<SellerProductItem> products;
  final Function(SellerProductItem) onEdit;
  final Function(int) onDelete;

  const ProductTableWidget({
    super.key,
    required this.products,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
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
                    onPressed: () => onEdit(item),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                    onPressed: () => onDelete(item.id),
                  ),
                ],
              ),
            ),
          ],
        )).toList(),
      ],
    );
  }
}