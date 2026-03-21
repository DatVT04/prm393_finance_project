// lib/src/layout/main_layout.dart
import 'package:flutter/material.dart';
import 'package:prm393_finance_project/src/core/constants/app_constants.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transactions/transaction_screen.dart';
import '../features/reports/report_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/ai/ai_assistant_screen.dart';
import 'package:prm393_finance_project/src/features/budgets/screens/budget_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = AppConstants.dashboardIndex;
  int _previousIndex = AppConstants.dashboardIndex; // Track last normal tab
  Offset? _fabPosition; // Store FAB position

  void _goToTransactions() {
    setState(() {
      _previousIndex = AppConstants.transactionsIndex;
      _selectedIndex = AppConstants.transactionsIndex;
    });
  }

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
      if (index < 5) {
        _previousIndex = index; // Update last active tab
      }
    });
  }

  void _toggleAiAssistant() {
    setState(() {
      if (_selectedIndex == 5) {
        // We are in AI mode, go back to previous normal tab
        _selectedIndex = _previousIndex;
      } else {
        // We are on a normal tab, store it and go to AI
        _previousIndex = _selectedIndex;
        _selectedIndex = 5;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadFabPosition();
  }

  Future<void> _loadFabPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('fab_dx');
    final dy = prefs.getDouble('fab_dy');
    if (dx != null && dy != null) {
      setState(() {
        _fabPosition = Offset(dx, dy);
      });
    }
  }

  Future<void> _saveFabPosition() async {
    if (_fabPosition == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fab_dx', _fabPosition!.dx);
    await prefs.setDouble('fab_dy', _fabPosition!.dy);
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
        final width = constraints.maxWidth;
        final theme = Theme.of(context);

        // Mobile Layout: Bottom Navigation Bar
        if (width < AppConstants.mobileBreakpoint) {
          final size = MediaQuery.of(context).size;
          // Initial position (bottom right)
          _fabPosition ??= Offset(size.width - 80, size.height - 180);

          return Stack(
            children: [
              Scaffold(
                body: IndexedStack(
                  index: _selectedIndex,
                  children: _screens,
                ),
                bottomNavigationBar: NavigationBar(
                  key: ValueKey('nav_bar_$localeSuffix'),
                  selectedIndex: _selectedIndex > 4 ? _previousIndex : _selectedIndex,
                  onDestinationSelected: (index) {
                    _onDestinationSelected(index);
                  },
                  destinations: mobileDestinations,
                ),
              ),
              Positioned(
                left: _fabPosition!.dx,
                top: _fabPosition!.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _fabPosition = Offset(
                        (_fabPosition!.dx + details.delta.dx).clamp(16.0, size.width - 76.0),
                        (_fabPosition!.dy + details.delta.dy).clamp(80.0, size.height - 150.0),
                      );
                    });
                  },
                  onPanEnd: (_) {
                    _saveFabPosition();
                  },
                  child: FloatingActionButton(
                    onPressed: _toggleAiAssistant,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        // Desktop/Web Layout: Side Navigation Rail
        else {
          final isExtended = width >= AppConstants.desktopBreakpoint;
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  key: ValueKey('nav_rail_$localeSuffix'),
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
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

