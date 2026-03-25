import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/services/export_service.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import '../transactions/providers/finance_providers.dart';
import 'models/category_report_data.dart';
import 'widgets/category_breakdown_list.dart';
import 'widgets/expenses_pie_chart.dart';
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

  Map<String, CategoryReportData> _categoryTotals(List<FinancialEntryModel> list, String type) {
    final map = <String, CategoryReportData>{};
    for (final e in list) {
      if (e.type != type) continue;
      final name = e.categoryDisplayName;
      if (!map.containsKey(name)) {
        map[name] = CategoryReportData(
          name: name,
          totalAmount: e.amount,
          iconName: e.categoryIconName,
          colorHex: e.categoryColorHex,
        );
      } else {
        final existing = map[name]!;
        map[name] = CategoryReportData(
          name: name,
          totalAmount: existing.totalAmount + e.amount,
          iconName: existing.iconName ?? e.categoryIconName,
          colorHex: existing.colorHex ?? e.categoryColorHex,
        );
      }
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
                ToastNotification.show(
                  context,
                  'no_data_to_export'.tr(),
                  status: ToastStatus.warning,
                );
                return;
              }

              final renderBox = context.findRenderObject() as RenderBox?;
              final position = renderBox != null 
                  ? renderBox.localToGlobal(Offset.zero) & renderBox.size
                  : null;

              try {
                if (value == 'excel') {
                  await ExportService.exportToExcel(list, sharePositionOrigin: position);
                }
                if (value == 'pdf') {
                  await ExportService.exportToPdf(list, sharePositionOrigin: position);
                }

                ToastNotification.show(
                  context,
                  'Export thành công',
                  status: ToastStatus.success,
                );
              } catch (e) {
                ToastNotification.show(
                  context,
                  'Export error: $e',
                  status: ToastStatus.error,
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
