// lib/src/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';

// Định nghĩa hàm định dạng số tiền thay thế cho NumberFormat từ package:intl
String formatCurrency(num amount) {
  return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ";
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng hàm formatCurrency thay cho NumberFormat
    final formattedAmount = formatCurrency(25000000);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Xin chào, User!",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),

          // Card Tổng tiền
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              formattedAmount,
              style: const TextStyle(color: Colors.white, fontSize: 32),
            ),
          ),

          // ... Phần Chart và List code tiếp ở dưới ...
        ],
      ),
    );
  }
}
