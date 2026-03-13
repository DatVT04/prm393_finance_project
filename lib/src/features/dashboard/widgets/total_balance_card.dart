import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:prm393_finance_project/src/features/dashboard/providers/dashboard_providers.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';

class TotalBalanceCard extends ConsumerWidget {
  const TotalBalanceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat('#,###', context.locale.toString());

    final entriesAsync = ref.watch(entriesWithRefreshProvider);
    final accountsAsync = ref.watch(accountsProvider);

    final (income, expense, totalBalance) = entriesAsync.maybeWhen(
      data: (all) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = (now.month == 12)
            ? DateTime(now.year + 1, 1, 1)
            : DateTime(now.year, now.month + 1, 1);

        final monthEntries = all.where((e) {
          final d = e.transactionDate;
          return !d.isBefore(monthStart) && d.isBefore(monthEnd);
        }).toList();

        final inc = monthEntries
            .where((e) => e.type == 'INCOME')
            .fold<double>(0, (s, e) => s + e.amount);
        final exp = monthEntries
            .where((e) => e.type == 'EXPENSE')
            .fold<double>(0, (s, e) => s + e.amount);
        
        final bal = accountsAsync.maybeWhen(
          data: (list) => list.fold<double>(0, (s, a) => s + a.balance),
          orElse: () => inc - exp,
        );

        return (inc, exp, bal);
      },
      orElse: () => (0.0, 0.0, 0.0),
    );

    final balance = totalBalance;

    String formatMoney(double value) {
      final rounded = value.round();
      return '${currency.format(rounded)} đ';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'total_balance'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatMoney(balance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIncomeExpenseInfo(
                context,
                icon: FontAwesomeIcons.arrowUp,
                label: 'income'.tr(),
                amount: formatMoney(income),
                isIncome: true,
                onTap: null,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildIncomeExpenseInfo(
                context,
                icon: FontAwesomeIcons.arrowDown,
                label: 'expense'.tr(),
                amount: formatMoney(expense),
                isIncome: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseInfo(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String amount,
    required bool isIncome,
    VoidCallback? onTap,
  }) {
    final row = Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      child: row,
    );
  }
}
