import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

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
  String _selectedPeriod = 'month';
  String _selectedType = 'EXPENSE';

  DateTime _rangeStart() {
    final now = DateTime.now();
    if (_selectedPeriod == 'week') {
      final weekday = now.weekday;
      return DateTime(now.year, now.month, now.day - weekday + 1);
    }
    if (_selectedPeriod == 'month') {
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

  Map<String, double> _categoryTotals(List<FinancialEntryModel> list, String type) {
    final map = <String, double>{};
    for (final e in list) {
      if (e.type != type) continue;
      final name = e.categoryName ?? 'other'.tr();
      map[name] = (map[name] ?? 0) + e.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesWithRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('report_title'.tr()),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              final all = entriesAsync.valueOrNull;
              if (all == null) return;

              final list = _filterByPeriod(all);
              if (list.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('no_data_to_export'.tr())),
                );
                return;
              }

              try {
                if (value == 'excel') {
                  await ExportService.exportToExcel(list);
                }
                if (value == 'pdf') {
                  await ExportService.exportToPdf(list);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export thành công')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'excel', child: Text('export_excel'.tr())),
              PopupMenuItem(value: 'pdf', child: Text('export_pdf'.tr())),
            ],
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (all) {
          final list = _filterByPeriod(all);
          final totalExpense = list.where((e) => e.type == 'EXPENSE').fold<double>(0, (s, e) => s + e.amount);
          final totalIncome = list.where((e) => e.type == 'INCOME').fold<double>(0, (s, e) => s + e.amount);
          
          final categoryTotals = _categoryTotals(list, _selectedType);
          final sortedCategories = categoryTotals.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final topCategory = sortedCategories.isNotEmpty ? sortedCategories.first.key : 'other'.tr();

          String wrappedButtonLabel;
          String wrappedTitle;
          final now = DateTime.now();
          if (_selectedPeriod == 'week') {
            final start = _rangeStart();
            final end = _rangeEnd();
            final df = DateFormat('dd/MM', context.locale.toString());
            wrappedButtonLabel = 'look_back_week'.tr();
            wrappedTitle = '${df.format(start)} - ${df.format(end)}';
          } else if (_selectedPeriod == 'year') {
            wrappedButtonLabel = 'look_back_year'.tr();
            wrappedTitle = '${'year'.tr()} ${now.year}';
          } else {
            wrappedButtonLabel = 'look_back_month'.tr();
            wrappedTitle = DateFormat('MMMM yyyy', context.locale.toString()).format(now);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ReportPeriodSelector(
                  selectedPeriod: _selectedPeriod,
                  onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'EXPENSE', label: Text('expense'.tr()), icon: const Icon(Icons.remove_circle_outline)),
                    ButtonSegment(value: 'INCOME', label: Text('income'.tr()), icon: const Icon(Icons.add_circle_outline)),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (val) => setState(() => _selectedType = val.first),
                ),
                const SizedBox(height: 24),
                ReportSummaryCard(income: totalIncome, expense: totalExpense),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => MonthWrappedScreen(
                          entries: list,
                          monthName: wrappedTitle,
                          totalExpense: totalExpense,
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
                  _selectedType == 'EXPENSE' ? 'expense_analysis'.tr() : 'income_analysis'.tr(),
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
              Text('error_loading_data'.tr(), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
