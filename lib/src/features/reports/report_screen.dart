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
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedType == 'EXPENSE' ? 0 : 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
    // Watch for locale changes to rebuild correctly
    context.locale;
    final entriesAsync = ref.watch(entriesWithRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('report_title'.tr()),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'export_excel'.tr(),
            onPressed: () async {
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
                await ExportService.exportToExcel(list, sharePositionOrigin: position);
                
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
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (all) {
          final list = _filterByPeriod(all);
          final totalExpense = list.where((e) => e.type == 'EXPENSE').fold<double>(0, (s, e) => s + e.amount);
          final totalIncome = list.where((e) => e.type == 'INCOME').fold<double>(0, (s, e) => s + e.amount);
          
          final categoryTotals = _categoryTotals(list, _selectedType);

          return Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(_selectedPeriod, _selectedType),
              const SizedBox(height: 16),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildContent(all, 'EXPENSE'),
                    _buildContent(all, 'INCOME'),
                  ],
                ),
              ),
            ],
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

  void _onTypeChanged(String type) {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    _pageController.animateToPage(
      type == 'EXPENSE' ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    final type = index == 0 ? 'EXPENSE' : 'INCOME';
    if (_selectedType != type) {
      setState(() => _selectedType = type);
    }
  }

  Widget _buildHeader(String period, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportPeriodSelector(
            selectedPeriod: period,
            onPeriodChanged: (p) => setState(() => _selectedPeriod = p),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              segments: [
                ButtonSegment(
                  value: 'EXPENSE',
                  label: Text(
                    'expense'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                ),
                ButtonSegment(
                  value: 'INCOME',
                  label: Text(
                    'income'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                ),
              ],
              selected: {type},
              onSelectionChanged: (val) => _onTypeChanged(val.first),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<FinancialEntryModel> all, String type) {
    final list = _filterByPeriod(all);
    final totalExpense = list.where((e) => e.type == 'EXPENSE').fold<double>(0, (s, e) => s + e.amount);
    final totalIncome = list.where((e) => e.type == 'INCOME').fold<double>(0, (s, e) => s + e.amount);
    final categoryTotals = _categoryTotals(list, type);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final horizontalPadding = isWide ? 32.0 : 16.0;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 24),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              ReportSummaryCard(income: totalIncome, expense: totalExpense),
                              const SizedBox(height: 32),
                              _buildAnalysisSection(context, type, categoryTotals),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 3,
                          child: CategoryBreakdownList(data: categoryTotals),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ReportSummaryCard(income: totalIncome, expense: totalExpense),
                        const SizedBox(height: 32),
                        _buildAnalysisSection(context, type, categoryTotals),
                        const SizedBox(height: 32),
                        CategoryBreakdownList(data: categoryTotals),
                      ],
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisSection(BuildContext context, String type, Map<String, CategoryReportData> categoryTotals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type == 'EXPENSE' ? 'expense_analysis'.tr() : 'income_analysis'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 16),
        ExpensesPieChart(data: categoryTotals),
      ],
    );
  }
}
