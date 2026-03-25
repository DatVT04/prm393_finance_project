import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/core/constants/category_colors.dart';

class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({super.key, this.data = const {}});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (s, e) => s + e.value);

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'spending_details'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final e = entries[index];
            final percent = total > 0 ? e.value / total : 0.0;
            final color = CategoryColors.get(e.key);
            final amountStr = '${(e.value).toStringAsFixed(0).replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                  (m) => '${m[1]},',
                )} đ';
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconUtils.buildIcon(
                    null,
                    categoryName: e.key,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (e.key.toLowerCase() == 'khác' || e.key.toLowerCase() == 'other') ? e.key.tr() : e.key, 
                            style: const TextStyle(fontWeight: FontWeight.w600)
                          ),
                          Text(amountStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: percent,
                        color: color,
                        backgroundColor: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
