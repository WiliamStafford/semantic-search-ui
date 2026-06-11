import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/models/seller_registration_model.dart';

class SellerRequestCard extends StatelessWidget {
  final SellerRegistration seller;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const SellerRequestCard({
    super.key,
    required this.seller,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(seller.shopName),
        subtitle: Text("${seller.address}\n${seller.description}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: Icon(Icons.check_circle, color: Colors.green), onPressed: onApprove),
            IconButton(icon: Icon(Icons.cancel, color: Colors.red), onPressed: onReject),
          ],
        ),
      ),
    );
  }
}