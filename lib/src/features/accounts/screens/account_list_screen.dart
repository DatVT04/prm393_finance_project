import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import '../widgets/add_account_modal.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final currency = NumberFormat('#,###', context.locale.toString());

    return Scaffold(
      appBar: AppBar(
        title: Text('manage_accounts'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _openAddAccount(context, ref),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: accountsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('no_accounts_msg'.tr()),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _openAddAccount(context, ref),
                    child: Text('add_account_now'.tr()),
                  ),
                ],
              ),
            );
          }

          final totalBalance = list.fold<double>(0, (sum, item) => sum + item.balance);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'total_balance'.tr(),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${currency.format(totalBalance)} đ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final account = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: IconUtils.getColor(account.colorHex).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: IconUtils.buildIcon(
                            account.iconName,
                            categoryName: account.name, // using categoryName as generic fallback for name
                            color: IconUtils.getColor(account.colorHex),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          account.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${currency.format(account.balance)} đ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: account.balance >= 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openEditAccount(context, ref, account);
                            } else if (value == 'delete') {
                              _confirmDeleteAccount(context, ref, account);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 20), const SizedBox(width: 8), Text('edit'.tr())])),
                            PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 20, color: Colors.red), const SizedBox(width: 8), Text('delete'.tr(), style: const TextStyle(color: Colors.red))])),
                          ],
                        ),
                        onTap: () => _openEditAccount(context, ref, account),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Lỗi: $err')),
      ),
    );
  }

  void _openAddAccount(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const AddAccountModal(),
    );
    if (result == true) {
      refreshAccounts(ref);
    }
  }

  void _openEditAccount(BuildContext context, WidgetRef ref, AccountModel account) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddAccountModal(accountToEdit: account),
    );
    if (result == true) {
      refreshAccounts(ref);
    }
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref, AccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_account_title'.tr()),
        content: Text(
          'delete_account_msg'.tr(args: [account.name]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('cancel'.tr())),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(apiClientProvider).deleteAccount(account.id);
      if (!context.mounted) return;
      refreshAccounts(ref);
      ToastNotification.show(
        context,
        'account_deleted_msg'.tr(),
        status: ToastStatus.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      ToastNotification.show(
        context,
        e.toString(),
        status: ToastStatus.error,
      );
    }
  }
}
