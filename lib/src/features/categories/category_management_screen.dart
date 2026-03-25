import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';

import 'add_category_modal.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_category_title'.tr()),
        content: Text(
          'delete_category_msg'.tr(args: [category.displayName.tr()]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(apiClientProvider).deleteCategory(category.id);
      refreshCategories(ref);
      refreshEntries(ref);
      ref.invalidate(categoriesProvider);
      ref.invalidate(entriesProvider);
      if (!mounted) return;
      ToastNotification.show(
        context,
        'category_deleted_msg'.tr(),
        status: ToastStatus.success,
      );
    } catch (e) {
      if (!mounted) return;
      ToastNotification.show(
        context,
        '$e',
        status: ToastStatus.error,
      );
    }
  }

  Future<void> _openEditSheet(CategoryModel? existing) async {
    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddCategoryModal(existing: existing),
    );

    if (result == null || !mounted) return;
    try {
      final client = ref.read(apiClientProvider);
      if (existing != null) {
        await client.updateCategory(existing.id, result);
        refreshCategories(ref);
        refreshEntries(ref);
        ref.invalidate(categoriesProvider);
        ref.invalidate(entriesProvider);
        if (!mounted) return;
        ToastNotification.show(
          context,
          'category_updated_msg'.tr(),
          status: ToastStatus.success,
        );
      } else {
        await client.createCategory(result);
        refreshCategories(ref);
        refreshEntries(ref);
        ref.invalidate(categoriesProvider);
        ref.invalidate(entriesProvider);
        if (!mounted) return;
        ToastNotification.show(
          context,
          'category_added_msg'.tr(),
          status: ToastStatus.success,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastNotification.show(
        context,
        '$e',
        status: ToastStatus.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('category_management_title'.tr()),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: categoriesAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'no_categories_msg'.tr(),
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'add_first_category_hint'.tr(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          final sortedList = list.toList()
            ..sort((a, b) {
              final aIsOther = a.name.toLowerCase().contains('khác');
              final bIsOther = b.name.toLowerCase().contains('khác');
              if (aIsOther && !bIsOther) return -1;
              if (!aIsOther && bIsOther) return 1;
              return a.name.compareTo(b.name);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedList.length,
            itemBuilder: (context, index) {
              final c = sortedList[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: IconUtils.getColor(c.colorHex).withOpacity(0.2),
                    child: IconUtils.buildIcon(
                      c.iconName,
                      categoryName: c.name,
                      color: IconUtils.getColor(c.colorHex),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    c.displayName.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.type == 'INCOME' ? 'income_short'.tr() : 'expense_short'.tr(),
                        style: TextStyle(
                          color: c.type == 'INCOME' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  trailing: (c.isFixed || c.name.toLowerCase() == 'khác' || c.name.toLowerCase() == 'khác (thu nhập)')
                      ? null
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openEditSheet(c),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                              onPressed: () => _deleteCategory(c),
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                '${'error_loading_data'.tr()}.\n${'check_spam_msg'.tr()}', // Alternative for "Check backend"
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('$err', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditSheet(null),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

}
