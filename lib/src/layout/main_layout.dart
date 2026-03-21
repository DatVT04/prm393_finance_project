// lib/src/layout/main_layout.dart
import 'package:flutter/material.dart';
import 'package:prm393_finance_project/src/core/constants/app_constants.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transactions/transaction_screen.dart';
import '../features/reports/report_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/ai/ai_assistant_screen.dart';
import '../features/budgets/screens/budget_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = AppConstants.dashboardIndex;

  void _goToTransactions() => setState(() => _selectedIndex = AppConstants.transactionsIndex);

  List<Widget> get _screens => [
        DashboardScreen(onViewAllEntries: _goToTransactions),
        const TransactionScreen(),
        const BudgetScreen(),
        const ReportScreen(),
        const SettingsScreen(),
        const AiAssistantScreen(),
      ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access context.locale to ensure build() is called on every change
    final localeSuffix = context.locale.toString();

    // Define destinations inside build to access context for translation
    final List<NavigationDestination> mobileDestinations = [
      NavigationDestination(icon: const Icon(Icons.dashboard), label: 'dashboard'.tr()),
      NavigationDestination(
        icon: const Icon(Icons.account_balance_wallet),
        label: 'transactions'.tr(),
      ),
      NavigationDestination(
        icon: const Icon(Icons.assignment_turned_in),
        label: 'budgets'.tr() == 'budgets' ? 'Ngân sách' : 'budgets'.tr(),
      ),
      NavigationDestination(icon: const Icon(Icons.bar_chart), label: 'reports'.tr()),
      NavigationDestination(icon: const Icon(Icons.settings), label: 'settings'.tr()),
      NavigationDestination(icon: const Icon(Icons.auto_awesome), label: 'ai_assistant'.tr()),
    ];

    final List<NavigationRailDestination> desktopDestinations = [
      NavigationRailDestination(
        icon: const Icon(Icons.dashboard),
        label: Text('dashboard'.tr()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.account_balance_wallet),
        label: Text('transactions'.tr()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.assignment_turned_in),
        label: Text('budgets'.tr() == 'budgets' ? 'Ngân sách' : 'budgets'.tr()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.bar_chart),
        label: Text('reports'.tr()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.settings),
        label: Text('settings'.tr()),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.auto_awesome),
        label: Text('ai_assistant'.tr()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile Layout: Bottom Navigation Bar
        if (constraints.maxWidth < AppConstants.mobileBreakpoint) {
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: NavigationBar(
              key: ValueKey('nav_bar_$localeSuffix'),
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: mobileDestinations,
            ),
          );
        }
        // Desktop/Web Layout: Side Navigation Rail
        else {
          final isExtended = constraints.maxWidth >= AppConstants.desktopBreakpoint;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  key: ValueKey('nav_rail_$localeSuffix'),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  // Khi extended = true, labelType phải là null hoặc none
                  // Khi extended = false, có thể dùng all
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  extended: isExtended,
                  destinations: desktopDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
