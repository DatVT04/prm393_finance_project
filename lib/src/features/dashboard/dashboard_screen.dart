// lib/src/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'widgets/home_app_bar.dart';
import 'widgets/total_balance_card.dart';
import 'widgets/quick_action_buttons.dart';
import 'widgets/recent_transactions_list.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            HomeAppBar(),
            SizedBox(height: 24),
            TotalBalanceCard(),
            SizedBox(height: 24),
            QuickActionButtons(),
            SizedBox(height: 32),
            RecentTransactionsList(),
          ],
        ),
      ),
    );
  }
}
