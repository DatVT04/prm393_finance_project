import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Giao dịch gần đây',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
          ],
        ),
        const SizedBox(height: 12),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _TransactionItem(
              icon: FontAwesomeIcons.spotify,
              title: 'Spotify Premium',
              date: 'Hôm nay, 10:00 AM',
              amount: '- 59,000 đ',
              color: Colors.green,
            ),
            _TransactionItem(
              icon: FontAwesomeIcons.burger,
              title: 'Ăn trưa (McDonalds)',
              date: 'Hôm nay, 12:30 PM',
              amount: '- 120,000 đ',
              color: Colors.orange,
            ),
            _TransactionItem(
              icon: FontAwesomeIcons.briefcase,
              title: 'Lương tháng 1',
              date: 'Hôm qua, 05:00 PM',
              amount: '+ 25,000,000 đ',
              color: Colors.blue,
              isIncome: true,
            ),
            _TransactionItem(
              icon: FontAwesomeIcons.bagShopping,
              title: 'Siêu thị Go!',
              date: '21/01/2026',
              amount: '- 1,500,000 đ',
              color: Colors.purple,
            ),
            _TransactionItem(
              icon: FontAwesomeIcons.gasPump,
              title: 'Đổ xăng',
              date: '20/01/2026',
              amount: '- 80,000 đ',
              color: Colors.redAccent,
            ),
          ],
        ),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String date;
  final String amount;
  final Color color;
  final bool isIncome;

  const _TransactionItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.amount,
    required this.color,
    this.isIncome = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isIncome ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
