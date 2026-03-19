import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';

/// "Nhìn lại một tháng" - Spotify Wrapped style.
class MonthWrappedScreen extends StatelessWidget {
  const MonthWrappedScreen({
    super.key,
    required this.entries,
    required this.monthName,
    required this.totalExpense,
    required this.topCategory,
    required this.entryCount,
  });

  final List<FinancialEntryModel> entries;
  final String monthName;
  final double totalExpense;
  final String topCategory;
  final int entryCount;

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,###', context.locale.toString());
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'back'.tr(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Text(
                'look_back'.tr(args: [monthName]),
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _buildCard(
                context,
                child: Column(
                  children: [
                    Text(
                      'total_expense'.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${nf.format(totalExpense)} ${context.locale.languageCode == 'vi' ? 'đ' : '\$'}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                context,
                child: Column(
                  children: [
                    Text(
                      'top_spending_category'.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topCategory.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildCard(
                context,
                child: Column(
                  children: [
                    Text(
                      'notes_saved'.tr(),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$entryCount',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: child,
    );
  }
}
