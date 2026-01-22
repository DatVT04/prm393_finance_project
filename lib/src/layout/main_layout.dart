// lib/src/layout/main_layout.dart
import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/transactions/transaction_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = AppConstants.dashboardIndex;

  // Danh sách các màn hình con
  final List<Widget> _screens = [
    const DashboardScreen(), // Màn hình 1: Dashboard
    const TransactionScreen(), // Màn hình 2: Giao dịch
    const Center(
      child: Text("Màn hình Báo cáo (Đang phát triển)"),
    ), // Placeholder Member 3
    const Center(
      child: Text("Cài đặt (Đang phát triển)"),
    ), // Placeholder Member 5
  ];

  // Navigation destinations cho cả Mobile và Desktop
  final List<NavigationDestination> _mobileDestinations = const [
    NavigationDestination(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet),
      label: 'Giao dịch',
    ),
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Cài đặt'),
  ];

  final List<NavigationRailDestination> _desktopDestinations = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard),
      label: Text('Tổng quan'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.account_balance_wallet),
      label: Text('Giao dịch'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bar_chart),
      label: Text('Báo cáo'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings),
      label: Text('Cài đặt'),
    ),
  ];

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile Layout: Bottom Navigation Bar
        if (constraints.maxWidth < AppConstants.mobileBreakpoint) {
          return Scaffold(
            body: _screens[_selectedIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              destinations: _mobileDestinations,
            ),
          );
        }
        // Desktop/Web Layout: Side Navigation Rail
        else {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  labelType: NavigationRailLabelType.all,
                  extended:
                      constraints.maxWidth >= AppConstants.desktopBreakpoint,
                  destinations: _desktopDestinations,
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: _screens[_selectedIndex]),
              ],
            ),
          );
        }
      },
    );
  }
}
