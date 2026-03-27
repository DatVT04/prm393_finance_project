import 'package:image_picker/image_picker.dart';
import 'package:prm393_finance_project/src/core/constants/api_constants.dart';
import 'package:prm393_finance_project/src/core/state/app_state.dart';
import 'package:prm393_finance_project/src/features/auth/auth_provider.dart';
import 'package:prm393_finance_project/src/features/auth/forgot_password_screen.dart';
import 'package:prm393_finance_project/src/features/categories/category_list_screen.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;
import 'package:easy_localization/easy_localization.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  String _avatarInitials(String rawName) {
    final parts = rawName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

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
      ToastNotification.show(
        context,
        'avatar_updated_msg'.tr(),
        status: ToastStatus.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastNotification.show(
        context,
        'Lỗi: $e',
        status: ToastStatus.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showEditNameDialog() {
    final currentName = ref.read(userProfileProvider).displayName ?? '';
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('edit_name'.tr()),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'display_name_label'.tr(),
                hintText: 'display_name_hint'.tr(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newName = controller.text.trim();
                        if (newName.isEmpty) {
                          ToastNotification.show(
                            context,
                            'display_name_required'.tr(),
                            status: ToastStatus.warning,
                          );
                          return;
                        }
                        setState(() => isSaving = true);
                        try {
                          await ref.read(apiClientProvider).updateDisplayName(newName);
                          await ref.read(currentUserIdProvider.notifier).updateDisplayName(newName);
                          if (!mounted) return;
                          Navigator.pop(ctx);
                          ToastNotification.show(
                            context,
                            'name_updated_msg'.tr(),
                            status: ToastStatus.success,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => isSaving = false);
                          ToastNotification.show(
                            context,
                            'Lỗi: $e',
                            status: ToastStatus.error,
                          );
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('save'.tr()),
              ),
            ],
          ),
        );
      },
    );
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
        title: Text('settings'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== PROFILE =====
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
                              : null,
                          child: (avatar == null || avatar.isEmpty)
                              ? Text(
                                  _avatarInitials(name),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
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
                        Text('Cá nhân hóa trải nghiệm của bạn'.tr()),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _showEditNameDialog,
                    icon: const Icon(Icons.edit),
                    tooltip: 'edit_name'.tr(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text('change_password'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePasswordDialog,
            ),
          ),

          const SizedBox(height: 24),

          // ===== THEME =====
          Card(
            child: SwitchListTile(
              value: appState.themeMode == ThemeMode.dark,
              onChanged: (value) {
                appState.toggleTheme();
              },
              title: Text('dark_mode'.tr()),
              subtitle: Text('dark_light_mode'.tr()),
              secondary: Icon(appState.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode),
            ),
          ),

          const SizedBox(height: 8),

          // ===== LANGUAGE =====
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text('change_language'.tr()),
              subtitle: Text(
                context.locale.languageCode == 'vi'
                    ? 'vietnamese'.tr()
                    : context.locale.languageCode == 'en'
                        ? 'english'.tr()
                        : context.locale.languageCode == 'ja'
                            ? 'japanese'.tr()
                            : context.locale.languageCode == 'ko'
                                ? 'korean'.tr()
                                : 'chinese'.tr(),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                _showLanguageDialog();
              },
            ),
          ),

          const SizedBox(height: 8),

          // ===== DATA =====
          Card(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: Text('manage_categories'.tr()),
              subtitle: Text('Thêm, sửa, xóa danh mục chi tiêu'.tr()),
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

          const SizedBox(height: 8),

          // ===== ABOUT =====
          Card(
            child: Stack(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('group_info'.tr()),
                  subtitle: Text('prm_finance_subtitle'.tr()),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutDialog();
                  },
                ),
                Positioned(
                  left: 4,
                  bottom: 4,
                  child: IconButton(
                    icon: Icon(Icons.vpn_key_outlined, 
                      size: 16, 
                      color: theme.colorScheme.primary.withOpacity(0.3)
                    ),
                    onPressed: _showAiKeyDialog,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'AI Gemini API Key',
                  ),
                ),
              ],
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
        title: Text(
          'change_password'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'change_pass_hint'.tr(),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: oldPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'old_pass_label'.tr(),
                  prefixIcon: const Icon(Icons.lock_open),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (v) => formKey.currentState?.validate(),
                validator: (v) =>
                    v == null || v.isEmpty ? 'old_pass_required'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'new_pass_label'.tr(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'new_pass_required'.tr();
                  if (v.length < 6) return 'min_6_chars'.tr();
                  if (v == oldPassCtrl.text) return 'new_pass_same_as_old'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'confirm_pass_label'.tr(),
                  prefixIcon: const Icon(Icons.check_circle_outline),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (v) =>
                    v != newPassCtrl.text ? 'pass_mismatch'.tr() : null,
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
                child: Text('forgot_password'.tr()),
                ),
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr(), style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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
                ToastNotification.show(
                  context,
                  'pass_updated_msg'.tr(),
                  status: ToastStatus.success,
                );
              } catch (e) {
                ToastNotification.show(
                  context,
                  'Lỗi: $e',
                  status: ToastStatus.error,
                );
              }
            },
            child: Text('update'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('change_language'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: Text('english'.tr()),
              trailing: context.locale.languageCode == 'en' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇻🇳', style: TextStyle(fontSize: 24)),
              title: Text('vietnamese'.tr()),
              trailing: context.locale.languageCode == 'vi' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.setLocale(const Locale('vi'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇯🇵', style: TextStyle(fontSize: 24)),
              title: Text('japanese'.tr()),
              trailing: context.locale.languageCode == 'ja' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.setLocale(const Locale('ja'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇰🇷', style: TextStyle(fontSize: 24)),
              title: Text('korean'.tr()),
              trailing: context.locale.languageCode == 'ko' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.setLocale(const Locale('ko'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇨🇳', style: TextStyle(fontSize: 24)),
              title: Text('chinese'.tr()),
              trailing: context.locale.languageCode == 'zh' ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                context.setLocale(const Locale('zh'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
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
      applicationName: 'app_title'.tr(),
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.account_balance_wallet,
        size: 40,
        color: theme.colorScheme.primary,
      ),
      children: [
        const SizedBox(height: 16),
        Text('${'subject_label'.tr()}: PRM393'),
        Text('${'group_label'.tr()}: 한국어'),
        const SizedBox(height: 8),
        Text('${'members_label'.tr()}:'),
        const Text('- Bùi Đức Chương (Leader)'),
        const Text('- Nguyễn Hữu Long'),
        const Text('- Nguyễn Danh Huy'),
        const Text('- Nguyễn Văn Sỹ'),
        const Text('- Vũ Tiến Đạt'),
      ],
    );
  }

  // ===== AI KEY DIALOG =====
  void _showAiKeyDialog() async {
    final theme = Theme.of(context);
    final controller = TextEditingController();
    bool isSaving = false;
    bool hasKey = false;
    
    // Initial status check
    try {
      hasKey = await ref.read(apiClientProvider).getAiApiKeyStatus();
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Gemini API Key'.tr()),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ai_key_dialog_desc'.tr(args: [hasKey ? 'active_key'.tr() : 'inactive_key'.tr()]),
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (!hasKey) ...[
                TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'api_key_hint'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'personal_key_in_use'.tr(),
                          style: const TextStyle(color: Colors.green, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'ai_key_note'.tr(),
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            if (hasKey)
              TextButton(
                onPressed: isSaving ? null : () async {
                  setDialogState(() => isSaving = true);
                  try {
                    await ref.read(apiClientProvider).deleteAiApiKey();
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ToastNotification.show(context, 'api_key_deleted'.tr());
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    ToastNotification.show(context, 'Lỗi: $e', status: ToastStatus.error);
                  }
                },
                child: Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: Text('cancel'.tr()),
            ),
            if (!hasKey)
              ElevatedButton(
                onPressed: isSaving ? null : () async {
                  final key = controller.text.trim();
                  if (key.isEmpty) return;
                  setDialogState(() => isSaving = true);
                  try {
                    await ref.read(apiClientProvider).saveAiApiKey(key);
                    if (!mounted) return;
                    Navigator.pop(ctx);
                    ToastNotification.show(context, 'api_key_saved'.tr(), status: ToastStatus.success);
                  } catch (e) {
                    setDialogState(() => isSaving = false);
                    ToastNotification.show(context, 'Lỗi: $e', status: ToastStatus.error);
                  }
                },
                child: isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('save'.tr()),
              ),
          ],
        ),
      ),
    );
  }
}
