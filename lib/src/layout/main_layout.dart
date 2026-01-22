// lib/src/layout/main_layout.dart
import 'package:flutter/material.dart';
import '../features/dashboard/dashboard_screen.dart'; // Import màn hình Dashboard
import '../features/transactions/transaction_screen.dart'; // Import màn hình Transaction

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Danh sách các màn hình con
  final List<Widget> _screens = [
    const DashboardScreen(), // Màn hình 1: Dashboard
    const TransactionScreen(), // Màn hình 2: Giao dịch
    const Center(child: Text("Màn hình Báo cáo (Đang phát triển)")),   // Placeholder Member 3
    const Center(child: Text("Cài đặt (Đang phát triển)")),            // Placeholder Member 5
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // --- MOBILE LAYOUT ---
          return Scaffold(
            body: _screens[_selectedIndex], // Hiển thị màn hình tương ứng
            bottomNavigationBar: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'Tổng quan'),
                NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Giao dịch'),
                NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
                NavigationDestination(icon: Icon(Icons.settings), label: 'Cài đặt'),
              ],
            ),
          );
        } else {
          // --- DESKTOP/WEB LAYOUT ---
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Tổng quan')),
                    NavigationRailDestination(icon: Icon(Icons.account_balance_wallet), label: Text('Giao dịch')),
                    NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Báo cáo')),
                    NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Cài đặt')),
                  ],
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