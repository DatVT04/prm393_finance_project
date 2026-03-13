import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:prm393_finance_project/src/core/constants/category_colors.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import '../../transactions/providers/finance_providers.dart';
import '../../transactions/widgets/add_entry_modal.dart';

class RecentTransactionsList extends ConsumerWidget {
  const RecentTransactionsList({super.key, this.onViewAll});

  final VoidCallback? onViewAll;

  static IconData _icon(String? name) {
    switch (name) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(entriesWithRefreshProvider);
    final nf = NumberFormat('#,###', 'vi_VN');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ghi chú gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('Xem tất cả'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        entriesAsync.when(
          data: (list) {
            final recent = list.take(5).toList();
            if (recent.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Chưa có ghi chú. Thêm từ tab Ghi chú.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final e = recent[index];
                final dateStr = DateFormat('dd/MM').format(e.transactionDate);
                final color = CategoryColors.get(e.categoryName ?? '');
                return InkWell(
                  onTap: () async {
                    final updated = await showModalBottomSheet<FinancialEntryModel>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => AddEntryModal(entryToEdit: e),
                    );
                    if (updated != null) {
                      refreshEntries(ref);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(_icon(e.categoryName), color: color, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.categoryName ?? 'Khác',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${e.type == 'INCOME' ? '+' : '-'}${nf.format(e.amount)} đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: e.type == 'INCOME' ? Colors.green[600] : const Color(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Không tải được dữ liệu',
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
