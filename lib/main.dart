import 'package:flutter/material.dart';
import 'package:semantic_search_ui/features/auth/presentation/pages/login_page.dart'; // Import đúng path
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}