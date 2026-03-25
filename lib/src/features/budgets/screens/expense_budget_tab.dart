import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';

import '../../../core/models/budget_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/network/finance_api_client.dart';
import '../../transactions/providers/finance_providers.dart';
import '../providers/budget_providers.dart';
import '../widgets/add_budget_dialog.dart';

class ExpenseBudgetTab extends ConsumerStatefulWidget {
  const ExpenseBudgetTab({super.key});

  @override
  ConsumerState<ExpenseBudgetTab> createState() => _ExpenseBudgetTabState();
}

class _ExpenseBudgetTabState extends ConsumerState<ExpenseBudgetTab> {
  DateTime _selectedDate =
      DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _addOrEdit(BudgetModel? budget) async {
    final success = await showDialog<bool>(
      context: context,
      builder: (_) => AddBudgetDialog(
        budgetToEdit: budget,
        categoryType: 'EXPENSE',
      ),
    );
    if (success == true) {
      refreshBudgets(ref);
    }
  }

  Future<void> _delete(BudgetModel b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_budget_confirm'.tr()),
        content: Text('delete_budget_body'.tr()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiClientProvider).deleteBudget(b.id!);
        refreshBudgets(ref);
      } catch (e) {
        if (!mounted) return;
        ToastNotification.show(
          context,
          '${'error'.tr()}: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  double _getSpentAmount(int categoryId, List entries) {
    return entries.where((e) {
      final date = e.transactionDate as DateTime;
      return e.categoryId == categoryId &&
          e.type == 'EXPENSE' &&
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month;
    }).fold<double>(0, (s, e) => s + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsWithRefreshProvider);
    final entriesAsync = ref.watch(entriesWithRefreshProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final cats = categoriesAsync.valueOrNull ?? [];
    // Only expense categories
    final expenseCatIds =
        cats.where((c) => c.type == 'EXPENSE').map((c) => c.id).toSet();

    return Scaffold(
      body: Column(
        children: [
          _buildMonthPicker(),
          Expanded(
            child: budgetsAsync.when(
              data: (list) {
                final currentBudgets = list.where((b) {
                  return b.startDate.year == _selectedDate.year &&
                      b.startDate.month == _selectedDate.month &&
                      expenseCatIds.contains(b.categoryId);
                }).toList();

                if (currentBudgets.isEmpty) {
                  return _buildEmptyState();
                }

                return entriesAsync.when(
                  data: (entries) => ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: currentBudgets.length,
                    itemBuilder: (ctx, idx) {
                      final b = currentBudgets[idx];
                      final spent = _getSpentAmount(b.categoryId, entries);
                      final cat =
                          cats.where((c) => c.id == b.categoryId).firstOrNull;
                      return _buildBudgetCard(b, spent, cat?.displayName.tr() ?? 'Unknown');
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      Center(child: Text('${'error_loading_data'.tr()}: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('${'error_loading_data'.tr()}: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_budget_fab',
        onPressed: () => _addOrEdit(null),
        child: const Icon(Icons.add_task),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _selectedDate =
                DateTime(_selectedDate.year, _selectedDate.month - 1)),
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() =>
                    _selectedDate = DateTime(picked.year, picked.month, 1));
              }
            },
            child: Text(
              DateFormat('MMMM yyyy', context.locale.toString())
                  .format(_selectedDate),
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _selectedDate =
                DateTime(_selectedDate.year, _selectedDate.month + 1)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined,
              size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'no_budget_set'.tr(),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _addOrEdit(null),
            child: Text('set_budget_now'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(BudgetModel b, double spent, String catName) {
    final double percent = (spent / b.amount).clamp(0.0, 1.0);
    final bool isOver = spent > b.amount;
    final color =
        isOver ? Colors.red : (percent > 0.8 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(catName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _addOrEdit(b)),
                    IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20, color: Colors.red),
                        onPressed: () => _delete(b)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent,
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
              backgroundColor: Colors.grey[200],
              color: color,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${NumberFormat("#,###", context.locale.toString()).format(spent)} / ${NumberFormat("#,###", context.locale.toString()).format(b.amount)} đ',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  '${(percent * 100).toInt()}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            if (isOver)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '⚠️ ${'over_budget'.tr()} ${NumberFormat("#,###", context.locale.toString()).format(spent - b.amount)} đ',
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
