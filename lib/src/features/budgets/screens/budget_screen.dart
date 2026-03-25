import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'expense_budget_tab.dart';
import 'income_target_tab.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access context.locale to ensure this widget rebuilds on locale change
    final localeSuffix = context.locale.toString();
    return Scaffold(
      appBar: AppBar(
        title: Text('planning_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.money_off),
              text: 'expense_budget'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.savings),
              text: 'income_target'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ExpenseBudgetTab(),
          IncomeTargetTab(),
        ],
      ),
    );
  }
}
