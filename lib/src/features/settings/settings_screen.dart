import 'package:image_picker/image_picker.dart';
import 'package:prm393_finance_project/src/core/constants/api_constants.dart';
import 'package:prm393_finance_project/src/core/constants/app_constants.dart';
import 'package:prm393_finance_project/src/core/state/app_state.dart';
import 'package:prm393_finance_project/src/features/auth/auth_provider.dart';
import 'package:prm393_finance_project/src/features/auth/forgot_password_screen.dart';
import 'package:prm393_finance_project/src/features/categories/category_list_screen.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await x.readAsBytes();
      final url = await ref.read(apiClientProvider).uploadAvatar(bytes, x.name);
      await ref.read(currentUserIdProvider.notifier).updateAvatar(url);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật avatar thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final avatar = profile.avatarUrl;
    final name = profile.displayName ?? 'User';
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== PROFILE =====
          _buildSectionTitle(context, 'Tài khoản'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : _pickAndUploadAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: theme.dividerColor,
                          backgroundImage: (avatar != null && avatar.isNotEmpty)
                              ? NetworkImage('${ApiConstants.baseUrl}$avatar')
                              : const NetworkImage(
                                      'https://ui-avatars.com/api/?background=random&name=User')
                                  as ImageProvider,
                        ),
                        if (_isLoading)
                          const Positioned.fill(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('Cá nhân hóa trải nghiệm của bạn',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Đổi mật khẩu'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePasswordDialog,
            ),
          ),

          const SizedBox(height: 24),

          // ===== THEME =====
          _buildSectionTitle(context, 'Giao diện'),
          Card(
            child: SwitchListTile(
              value: appState.themeMode == ThemeMode.dark,
              onChanged: (value) {
                appState.toggleTheme();
              },
              title: const Text('Chế độ tối'),
              subtitle: const Text('Dark / Light mode'),
              secondary: Icon(appState.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            ),
          ),

          const SizedBox(height: 24),

          // ===== DATA =====
          _buildSectionTitle(context, 'Dữ liệu'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Quản lý danh mục'),
              subtitle: const Text('Thêm, sửa, xóa danh mục chi tiêu'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CategoryListScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ===== ABOUT =====
          _buildSectionTitle(context, 'Thông tin'),
          Card(
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

  void _showChangePasswordDialog() {
    final theme = Theme.of(context);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Mật khẩu mới phải có ít nhất 6 ký tự để bảo mật tài khoản của bạn.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  prefixIcon: const Icon(Icons.lock_open),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Vui lòng nhập mật khẩu cũ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                  if (v.length < 6) return 'Tối thiểu 6 ký tự';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v != newPassCtrl.text ? 'Mật khẩu không khớp' : null,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Quên mật khẩu?'),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await ref
                    .read(apiClientProvider)
                    .updatePassword(oldPassCtrl.text, newPassCtrl.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đổi mật khẩu thành công'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  // ===== SECTION TITLE =====
  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ===== ABOUT DIALOG =====
  void _showAboutDialog() {
    final theme = Theme.of(context);
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.account_balance_wallet,
        size: 40,
        color: theme.colorScheme.primary,
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
