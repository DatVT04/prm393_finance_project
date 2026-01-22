import 'package:flutter/material.dart';

class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final List<Map<String, dynamic>> categories = [
      {
        'name': 'Ăn uống',
        'amount': '5,000,000 đ',
        'percent': 0.4,
        'color': const Color(0xFF0293ee),
        'icon': Icons.fastfood,
      },
      {
        'name': 'Mua sắm',
        'amount': '3,750,000 đ',
        'percent': 0.3,
        'color': const Color(0xFFf8b250),
        'icon': Icons.shopping_bag,
      },
      {
        'name': 'Di chuyển',
        'amount': '1,875,000 đ',
        'percent': 0.15,
        'color': const Color(0xFF845bef),
        'icon': Icons.directions_car,
      },
      {
        'name': 'Khác',
        'amount': '1,875,000 đ',
        'percent': 0.15,
        'color': const Color(0xFF13d38e),
        'icon': Icons.more_horiz,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết chi tiêu',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final category = categories[index];
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (category['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category['icon'] as IconData,
                    color: category['color'] as Color,
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
                            category['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            category['amount'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: category['percent'] as double,
                        color: category['color'] as Color,
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
