import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm393_finance_project/src/core/constants/app_constants.dart';
import 'package:prm393_finance_project/src/core/theme/theme_provider.dart';
import 'package:prm393_finance_project/src/features/categories/category_management_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    final mode = ref.read(themeModeProvider);
    _isDarkMode = mode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== THEME =====
          _buildSectionTitle('Giao diện'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              value: _isDarkMode,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
                ref.read(themeModeProvider.notifier).state =
                    value ? ThemeMode.dark : ThemeMode.light;
              },
              title: const Text('Chế độ tối'),
              subtitle: const Text('Dark / Light mode'),
              secondary: const Icon(Icons.dark_mode),
            ),
          ),

          const SizedBox(height: 24),

          // ===== DATA =====
          _buildSectionTitle('Dữ liệu'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Quản lý danh mục'),
              subtitle: const Text('Thêm, sửa, xóa danh mục chi tiêu'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CategoryManagementScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ===== ABOUT =====
          _buildSectionTitle('Thông tin'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Thông tin nhóm'),
              subtitle: const Text('PRM393 – Personal Finance'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showAboutDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // ===== ABOUT DIALOG =====
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.account_balance_wallet,
        size: 40,
        color: Colors.teal,
      ),
      children: const [
        SizedBox(height: 16),
        Text('Môn học: PRM393'),
        Text('Nhóm: 한국어'),
        SizedBox(height: 8),
        Text('Thành viên:'),
        Text('- Bùi Đức Chương (Leader)'),
        Text('- Nguyễn Hữu Long'),
        Text('- Nguyễn Danh Huy'),
        Text('- Nguyễn Văn Sỹ'),
        Text('- Vũ Tiến Đạt'),
      ],
    );
  }
}
