import 'package:flutter/material.dart';
import 'widgets/category_breakdown_list.dart';
import 'widgets/expenses_pie_chart.dart';
import 'widgets/report_period_selector.dart';
import 'widgets/report_summary_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _selectedPeriod = 'Tháng';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ReportPeriodSelector(
              selectedPeriod: _selectedPeriod,
              onPeriodChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
              },
            ),
            const SizedBox(height: 24),
            const ReportSummaryCard(income: 52000000, expense: 12500000),
            const SizedBox(height: 24),
            Text(
              'Phân tích chi tiêu',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const ExpensesPieChart(),
            const SizedBox(height: 24),
            const CategoryBreakdownList(),
            // Add some bottom padding
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
