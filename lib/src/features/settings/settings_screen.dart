import 'package:flutter/material.dart';

import 'package:prm393_finance_project/src/core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  String _language = 'Tiếng Việt';

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
              },
              title: const Text('Chế độ tối'),
              subtitle: const Text('Dark / Light mode'),
              secondary: const Icon(Icons.dark_mode),
            ),
          ),

          const SizedBox(height: 24),

          // ===== LANGUAGE =====
          _buildSectionTitle('Ngôn ngữ'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Ngôn ngữ'),
              subtitle: Text(_language),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLanguageDialog();
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

  // ===== LANGUAGE DIALOG =====
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn ngôn ngữ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('Tiếng Việt'),
                value: 'Tiếng Việt',
                groupValue: _language,
                onChanged: (value) {
                  setState(() {
                    _language = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('English'),
                value: 'English',
                groupValue: _language,
                onChanged: (value) {
                  setState(() {
                    _language = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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
        Text('Nhóm: Nhóm X'),
        SizedBox(height: 8),
        Text('Thành viên:'),
        Text('- Nguyễn Văn A'),
        Text('- Nguyễn Văn B'),
        Text('- Nguyễn Văn Sỹ'),
      ],
    );
  }
}
