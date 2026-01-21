// lib/main.dart
import 'package:flutter/material.dart';
import 'src/layout/main_layout.dart'; // Import file layout đã tách

void main() {
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: const MainLayout(), // Gọi Widget MainLayout từ file khác
    );
  }
}