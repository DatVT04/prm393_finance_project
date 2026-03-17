import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'providers/finance_providers.dart';
import 'widgets/add_entry_modal.dart';
import 'widgets/ai_quick_entry_sheet.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
  String _dateFilter = 'all';
  DateTime? _customDate;

  void _openAddEntry() async {
    final created = await showModalBottomSheet<FinancialEntryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AddEntryModal(),
    );
    if (created != null) {
      refreshEntries(ref);
      refreshAccounts(ref);
    }
  }

  void _openAiQuickEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AiQuickEntrySheet(),
    );
  }

  Future<bool> _deleteEntry(FinancialEntryModel entry) async {
    try {
      await ref.read(apiClientProvider).deleteEntry(entry.id);
      refreshEntries(ref);
      refreshAccounts(ref);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('deleted_entry_msg'.tr()), backgroundColor: Colors.orange),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Map<String, List<FinancialEntryModel>> _groupByDate(List<FinancialEntryModel> list) {
    final map = <String, List<FinancialEntryModel>>{};
    for (final e in list) {
      final key = DateFormat('dd/MM/yyyy', context.locale.toString()).format(e.transactionDate);
      map.putIfAbsent(key, () => []).add(e);
    }
    for (final l in map.values) {
      l.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    }
    return map;
  }

  List<FinancialEntryModel> _filterByDate(List<FinancialEntryModel> list) {
    if (_dateFilter == 'all') return list;

    final now = DateTime.now();
    if (_dateFilter == 'this_month') {
      return list.where((e) =>
          e.transactionDate.year == now.year &&
          e.transactionDate.month == now.month).toList();
    }
    if (_dateFilter == 'this_year') {
      return list.where((e) => e.transactionDate.year == now.year).toList();
    }
    if (_dateFilter == 'day' && _customDate != null) {
      return list.where((e) =>
          e.transactionDate.year == _customDate!.year &&
          e.transactionDate.month == _customDate!.month &&
          e.transactionDate.day == _customDate!.day).toList();
    }
    return list;
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final initial = _customDate ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (selected != null) {
      setState(() {
        _customDate = selected;
        _dateFilter = 'day';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterTag = ref.watch(filterTagProvider);
    final entriesAsync = ref.watch(entriesFilteredProvider(filterTag));

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions_title'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (filterTag != null && filterTag.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text('#$filterTag'),
                onDeleted: () {
                  ref.read(filterTagProvider.notifier).state = null;
                },
              ),
            ),
          IconButton(
            onPressed: () {
              final controller = TextEditingController(text: filterTag ?? '');
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('filter_by_tag'.tr()),
                  content: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'enter_tag_hint'.tr(),
                      prefixText: '#',
                    ),
                    onSubmitted: (v) {
                      final t = v.trim();
                      ref.read(filterTagProvider.notifier).state =
                          t.isEmpty ? null : (t.startsWith('#') ? t.substring(1) : t);
                      Navigator.pop(ctx);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        ref.read(filterTagProvider.notifier).state = null;
                        Navigator.pop(ctx);
                      },
                      child: Text('remove_filter'.tr()),
                    ),
                    TextButton(
                      onPressed: () {
                        final t = controller.text.trim();
                        ref.read(filterTagProvider.notifier).state =
                            t.isEmpty ? null : (t.startsWith('#') ? t.substring(1) : t);
                        Navigator.pop(ctx);
                      },
                      child: Text('apply'.tr()),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.filter_list),
            color: Colors.black87,
          ),
        ],
      ),
      body: entriesAsync.when(
        data: (list) {
          var displayList = _filterByDate(list);
          final grouped = _groupByDate(displayList);
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) {
              final da = DateFormat('dd/MM/yyyy', context.locale.toString()).parse(a);
              final db = DateFormat('dd/MM/yyyy', context.locale.toString()).parse(b);
              return db.compareTo(da);
            });
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateFilterChip('all'),
                      const SizedBox(width: 8),
                      _buildDateFilterChip('this_month'),
                      const SizedBox(width: 8),
                      _buildDateFilterChip('this_year'),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          _customDate != null
                              ? DateFormat('dd/MM/yyyy', context.locale.toString()).format(_customDate!)
                              : 'day'.tr(),
                        ),
                        avatar: const Icon(Icons.calendar_today, size: 18),
                        selected: _dateFilter == 'day',
                        onSelected: (_) => _pickCustomDate(),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                               filterTag != null ? '${'no_entries_with_tag'.tr()} #$filterTag' : 'no_entries_yet'.tr(),
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                               'add_entry_hint'.tr(),
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100, top: 8),
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, index) {
                          final dateStr = sortedKeys[index];
                          final items = grouped[dateStr]!;
                          final incomeTotal = items.where((e) => e.type == 'INCOME').fold<double>(0, (s, e) => s + e.amount);
                          final expenseTotal = items.where((e) => e.type == 'EXPENSE').fold<double>(0, (s, e) => s + e.amount);
                          final dailyNet = incomeTotal - expenseTotal;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDateHeader(dateStr),
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    Text(
                                      '${dailyNet >= 0 ? '+' : '-'}${NumberFormat("#,###", context.locale.toString()).format(dailyNet.abs())} đ',
                                      style: TextStyle(
                                          color: dailyNet >= 0 ? Colors.green[700] : Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              ...items.map((e) => _buildEntryItem(e)),
                            ],
                          );
                        },
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
              const SizedBox(height: 16),
              Text('$err', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'ai',
            onPressed: _openAiQuickEntry,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _openAddEntry,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterChip(String label) {
    final isSelected = _dateFilter == label;
    return ChoiceChip(
      label: Text(label.tr()),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _dateFilter = label;
          if (label != 'day') {
            _customDate = null;
          }
        });
      },
    );
  }

  String _formatDateHeader(String dateStr) {
    final now = DateTime.now();
    final todayStr = DateFormat('dd/MM/yyyy').format(now);
    final yesterdayStr = DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1)));
    if (dateStr == todayStr) return 'today'.tr();
    if (dateStr == yesterdayStr) return 'yesterday'.tr();
    return dateStr;
  }

  Widget _buildEntryItem(FinancialEntryModel e) {
    return Dismissible(
      key: Key('${e.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('delete_entry_confirm'.tr()),
            content: Text(
              'delete_entry_body'.tr(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('clear'.tr()),
              ),
            ],
          ),
        );
        if (confirmed != true) return false;
        return await _deleteEntry(e);
      },
      child: InkWell(
        onTap: () async {
          final updated = await showModalBottomSheet<FinancialEntryModel>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (ctx) => AddEntryModal(entryToEdit: e),
          );
          if (updated != null) {
            refreshEntries(ref);
            refreshAccounts(ref);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(e.categoryName ?? '').withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getCategoryIcon(e.categoryName ?? ''), color: _getCategoryColor(e.categoryName ?? ''), size: 20),
            ),
            title: Text(
              e.categoryName ?? 'other'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: (e.note != null && e.note!.isNotEmpty)
                ? Text(
                    e.note!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Text(
              '${e.type == 'INCOME' ? '+' : '-'}${NumberFormat("#,###", context.locale.toString()).format(e.amount)} đ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: e.type == 'INCOME' ? Colors.green[600] : Colors.red[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant;
      case 'Xăng xe':
        return Icons.local_gas_station;
      case 'Mua sắm':
        return Icons.shopping_bag;
      case 'Giải trí':
        return Icons.confirmation_number;
      case 'Y tế':
        return Icons.medical_services;
      case 'Giáo dục':
        return Icons.school;
      case 'Gửi xe':
        return Icons.local_parking;
      case 'Nạp tiền':
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống':
        return Colors.orange;
      case 'Xăng xe':
        return Colors.blue;
      case 'Mua sắm':
        return Colors.purple;
      case 'Giải trí':
        return Colors.pink;
      case 'Y tế':
        return Colors.red;
      case 'Giáo dục':
        return Colors.indigo;
      case 'Gửi xe':
        return Colors.brown;
      case 'Nạp tiền':
        return Colors.green;
      default:
        return Colors.teal;
    }
  }
}
