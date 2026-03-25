import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';

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
    context.locale;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: Theme.of(context).brightness == Brightness.light ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ] : [],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildItem(
                  context,
                  icon: FontAwesomeIcons.circleArrowDown,
                  color: const Color(0xFF2E7D32), // Success Green
                  label: 'total_income'.tr(),
                  amount: income,
                ),
              ),
              VerticalDivider(
                width: 32,
                thickness: 1,
                color: Theme.of(context).dividerColor,
                indent: 8,
                endIndent: 8,
              ),
              Expanded(
                child: _buildItem(
                  context,
                  icon: FontAwesomeIcons.circleArrowUp,
                  color: const Color(0xFFD32F2F), // Error Red
                  label: 'total_expense'.tr(),
                  amount: expense,
                ),
              ),
            ],
          ),
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
    final amountStr = CurrencyFormatter.format(context, amount);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            amountStr,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
