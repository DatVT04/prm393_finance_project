import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/services/export_service.dart';
import '../transactions/providers/finance_providers.dart';
import 'widgets/category_breakdown_list.dart';
import 'widgets/expenses_pie_chart.dart';
import 'widgets/month_wrapped_screen.dart';
import 'widgets/report_period_selector.dart';
import 'widgets/report_summary_card.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  String _selectedPeriod = 'Tháng';

  DateTime _rangeStart() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Tuần') {
      final weekday = now.weekday;
      return DateTime(now.year, now.month, now.day - weekday + 1);
    }
    if (_selectedPeriod == 'Tháng') {
      return DateTime(now.year, now.month, 1);
    }
    return DateTime(now.year, 1, 1);
  }

  DateTime _rangeEnd() => DateTime.now();

  List<FinancialEntryModel> _filterByPeriod(List<FinancialEntryModel> list) {
    final start = _rangeStart();
    final end = _rangeEnd();
    return list.where((e) {
      final d = e.transactionDate;
      return (d.isAfter(start.subtract(const Duration(days: 1))) && d.isBefore(end.add(const Duration(days: 1)))) ||
          d.isAtSameMomentAs(start) ||
          d.isAtSameMomentAs(end);
    }).toList();
  }

  Map<String, double> _categoryTotals(List<FinancialEntryModel> list) {
    final map = <String, double>{};
    for (final e in list) {
      if (e.type != 'EXPENSE') continue;
      final name = e.categoryName ?? 'Khác';
      map[name] = (map[name] ?? 0) + e.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesWithRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo thống kê'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              entriesAsync.when(
                data: (all) {
                  final list = _filterByPeriod(all);
                  if (list.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Không có dữ liệu để xuất')),
                    );
                    return;
                  }
                  if (value == 'excel') ExportService.exportToExcel(list);
                  if (value == 'pdf') ExportService.exportToPdf(list);
                },
                loading: () {},
                error: (_, __) {},
              );
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'excel', child: Text('Xuất Excel')),
              const PopupMenuItem(value: 'pdf', child: Text('Xuất PDF')),
            ],
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (all) {
          final list = _filterByPeriod(all);
          final expense = list.where((e) => e.type == 'EXPENSE').fold<double>(0, (s, e) => s + e.amount);
          final income = list.where((e) => e.type == 'INCOME').fold<double>(0, (s, e) => s + e.amount);
          final categoryTotals = _categoryTotals(list);
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topCategory = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'Khác';

          String wrappedButtonLabel;
          String wrappedTitle;
          final now = DateTime.now();
          if (_selectedPeriod == 'Tuần') {
            final start = _rangeStart();
            final end = _rangeEnd();
            final df = DateFormat('dd/MM', 'vi');
            wrappedButtonLabel = 'Nhìn lại tuần này';
            wrappedTitle = '${df.format(start)} - ${df.format(end)}';
          } else if (_selectedPeriod == 'Năm') {
            wrappedButtonLabel = 'Nhìn lại năm nay';
            wrappedTitle = 'Năm ${now.year}';
          } else {
            wrappedButtonLabel = 'Nhìn lại tháng này';
            wrappedTitle = DateFormat('MMMM yyyy', 'vi').format(now);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ReportPeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
                ),
                const SizedBox(height: 24),
                ReportSummaryCard(income: income, expense: expense),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => MonthWrappedScreen(
                          entries: list,
                          monthName: wrappedTitle,
                          totalExpense: expense,
                          topCategory: topCategory,
                          entryCount: list.length,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(wrappedButtonLabel),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Phân tích chi tiêu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ExpensesPieChart(data: categoryTotals),
                const SizedBox(height: 8),
                CategoryBreakdownList(data: categoryTotals),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text('Không tải được dữ liệu.', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
