import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ReportSummaryCard extends StatelessWidget {
  final double income;
  final double expense;

  const ReportSummaryCard({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: _buildItem(
                context,
                icon: FontAwesomeIcons.arrowDown,
                color: Colors.green,
                label: 'Tổng thu',
                amount: income,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.withOpacity(0.3),
            ),
            Expanded(
              child: _buildItem(
                context,
                icon: FontAwesomeIcons.arrowUp,
                color: Colors.red,
                label: 'Tổng chi',
                amount: expense,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required double amount,
  }) {
    // Simple formatter would be better, but for now simple string interpol
    // Ideally use intl NumberFormat
    final formattedAmount = '${(amount / 1000000).toStringAsFixed(1)}tr';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          formattedAmount,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
