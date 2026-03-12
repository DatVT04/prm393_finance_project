import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  String? _filterTag;

  void _openAddEntry() async {
    final created = await showModalBottomSheet<FinancialEntryModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AddEntryModal(),
    );
    if (created != null) {
      refreshEntries(ref);
    }
  }

  void _openAiQuickEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AiQuickEntrySheet(),
    );
  }

  Future<void> _deleteEntry(FinancialEntryModel entry) async {
    try {
      await ref.read(apiClientProvider).deleteEntry(entry.id);
      refreshEntries(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa ghi chú'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Map<String, List<FinancialEntryModel>> _groupByDate(List<FinancialEntryModel> list) {
    final map = <String, List<FinancialEntryModel>>{};
    for (final e in list) {
      final key = DateFormat('dd/MM/yyyy').format(e.transactionDate);
      map.putIfAbsent(key, () => []).add(e);
    }
    for (final l in map.values) {
      l.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(entriesWithRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ghi chú chi tiêu', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Lọc theo tag'),
                  content: TextField(
                    decoration: const InputDecoration(hintText: 'Nhập #tag'),
                    onSubmitted: (v) {
                      setState(() => _filterTag = v.trim().isEmpty ? null : v.trim());
                      Navigator.pop(ctx);
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() => _filterTag = null);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Bỏ lọc'),
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
          var displayList = list;
          if (_filterTag != null && _filterTag!.isNotEmpty) {
            displayList = list.where((e) => e.tags.any((t) => t.toLowerCase().contains(_filterTag!.toLowerCase()))).toList();
          }
          if (displayList.isEmpty) {
            return Center(
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
                    _filterTag != null ? 'Không có ghi chú với tag "$_filterTag"' : 'Chưa có ghi chú nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dùng nút (+) hoặc (★) để thêm nhanh',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final grouped = _groupByDate(displayList);
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) {
              final da = DateFormat('dd/MM/yyyy').parse(a);
              final db = DateFormat('dd/MM/yyyy').parse(b);
              return db.compareTo(da);
            });

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 100, top: 8),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateStr = sortedKeys[index];
              final items = grouped[dateStr]!;
              final dailyTotal = items.fold<double>(0, (s, e) => s + e.amount);
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
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '-${NumberFormat("#,###", "vi_VN").format(dailyTotal)} đ',
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  ...items.map((e) => _buildEntryItem(e)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Không tải được dữ liệu.\nKiểm tra backend đã chạy và kết nối mạng.', textAlign: TextAlign.center),
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
            child: const Icon(Icons.auto_awesome),
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

  String _formatDateHeader(String dateStr) {
    final now = DateTime.now();
    final today = DateFormat('dd/MM/yyyy').format(now);
    final yesterday = DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1)));
    if (dateStr == today) return 'Hôm nay';
    if (dateStr == yesterday) return 'Hôm qua';
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
      onDismissed: (_) => _deleteEntry(e),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF006D5B).withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
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
            e.categoryName ?? 'Khác',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: (e.note != null && e.note!.isNotEmpty)
              ? Text(
                  e.note!,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Text(
            '-${NumberFormat("#,###", "vi_VN").format(e.amount)} đ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE53935)),
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
      default:
        return Colors.teal;
    }
  }
}
