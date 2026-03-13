// lib/src/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/total_balance_card.dart';
import 'widgets/quick_action_buttons.dart';
import 'widgets/recent_transactions_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.onViewAllEntries});

  final VoidCallback? onViewAllEntries;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            const HomeAppBar(),
            const SizedBox(height: 24),
            const TotalBalanceCard(),
            const SizedBox(height: 32),
            RecentTransactionsList(onViewAll: onViewAllEntries),
          ],
        ),
      ),
    );
  }
}
