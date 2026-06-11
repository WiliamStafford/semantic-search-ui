import 'package:flutter/material.dart';

class CustomAdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAdminAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(75.0),
      child: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 75.0,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(75.0);
}