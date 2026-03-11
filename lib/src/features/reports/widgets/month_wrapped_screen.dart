import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';

/// "Nhìn lại một tháng" - Spotify Wrapped style.
class MonthWrappedScreen extends StatelessWidget {
  const MonthWrappedScreen({
    super.key,
    required this.entries,
    required this.monthName,
    required this.totalExpense,
    required this.topCategory,
    required this.entryCount,
  });

  final List<FinancialEntryModel> entries;
  final String monthName;
  final double totalExpense;
  final String topCategory;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', 'vi_VN');
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Text(
                'Nhìn lại $monthName',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nhật ký Tài chính Thông minh',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),
              _buildCard(
                child: Column(
                  children: [
                    Text(
                      'Tổng chi tiêu',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${nf.format(totalExpense)} đ',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFe94560),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                child: Column(
                  children: [
                    Text(
                      'Danh mục chi nhiều nhất',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topCategory,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                child: Column(
                  children: [
                    Text(
                      'Số ghi chú đã lưu',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$entryCount',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0f3460),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Chia sẻ báo cáo của bạn',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF16213e),
            const Color(0xFF0f3460),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFe94560).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
