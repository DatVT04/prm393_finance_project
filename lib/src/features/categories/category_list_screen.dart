import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';

import 'add_category_modal.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    textAlign: TextAlign.center,
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

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: sortedList.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final c = sortedList[index];
                final color = _parseColor(c.colorHex);
                final icon = _iconFromName(c.iconName);
                return GestureDetector(
                  onTap: (c.isFixed || c.name.toLowerCase() == 'khác')
                      ? null
                      : () => _openEdit(context, ref, c),
                  child: Hero(
                    tag: 'category_${c.id}',
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.4)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: color.withOpacity(0.2),
                                  child: IconUtils.buildIcon(
                                    c.iconName,
                                    categoryName: c.name,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                if (!(c.isFixed || c.name.toLowerCase() == 'khác'))
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => _showActionsBottomSheet(context, ref, c),
                                  ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              (c.name.toLowerCase() == 'khác' || c.name.toLowerCase() == 'other') ? c.name.tr() : c.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
                'error_loading_data'.tr(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$err',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context, ref, null),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.teal;
    final h = hex.startsWith('#') ? hex : '#$hex';
    if (h.length != 7) return Colors.teal;
    final r = int.tryParse(h.substring(1, 3), radix: 16);
    final g = int.tryParse(h.substring(3, 5), radix: 16);
    final b = int.tryParse(h.substring(5, 7), radix: 16);
    if (r == null || g == null || b == null) return Colors.teal;
    return Color.fromARGB(255, r, g, b);
  }

  IconData _iconFromName(String? name) {
    if (name == null || name.isEmpty) {
      return FontAwesomeIcons.shapes;
    }
    switch (name) {
      case 'utensils':
        return FontAwesomeIcons.utensils;
      case 'cartShopping':
        return FontAwesomeIcons.cartShopping;
      case 'moneyBillWave':
        return FontAwesomeIcons.moneyBillWave;
      case 'sackDollar':
        return FontAwesomeIcons.sackDollar;
      case 'piggyBank':
        return FontAwesomeIcons.piggyBank;
      case 'wallet':
        return FontAwesomeIcons.wallet;
      case 'film':
        return FontAwesomeIcons.film;
      case 'gamepad':
        return FontAwesomeIcons.gamepad;
      case 'heartbeat':
        return FontAwesomeIcons.heartPulse;
      case 'hospital':
        return FontAwesomeIcons.hospital;
      case 'stethoscope':
        return FontAwesomeIcons.stethoscope;
      case 'graduationCap':
        return FontAwesomeIcons.graduationCap;
      case 'bus':
        return FontAwesomeIcons.bus;
      case 'car':
        return FontAwesomeIcons.car;
      case 'motorcycle':
        return FontAwesomeIcons.motorcycle;
      case 'house':
        return FontAwesomeIcons.house;
      case 'lightbulb':
        return FontAwesomeIcons.lightbulb;
      case 'gift':
        return FontAwesomeIcons.gift;
      case 'plane':
        return FontAwesomeIcons.plane;
      case 'coffee':
        return FontAwesomeIcons.mugSaucer;
      default:
        return FontAwesomeIcons.shapes;
    }
  }

  Future<void> _openEdit(
    BuildContext context,
    WidgetRef ref,
    CategoryModel? existing,
  ) async {
    final result = await showModalBottomSheet<CategoryModel>(  //mở bottom sheet
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddCategoryModal(existing: existing),
    );

    if (result == null) return;   //user mở modal nhưng không lưu
    try {
      final client = ref.read(apiClientProvider);
      if (existing != null) {
        await client.updateCategory(existing.id, result);
        ToastNotification.show(
          context,
          'category_updated_msg'.tr(),
          status: ToastStatus.success,
        );
      } else {
        await client.createCategory(result);
        ToastNotification.show(
          context,
          'category_added_msg'.tr(),
          status: ToastStatus.success,
        );
      }
      refreshCategories(ref);
      refreshEntries(ref);
      refreshAccounts(ref);
    } catch (e) {
      ToastNotification.show(
        context,
        '$e',
        status: ToastStatus.error,
      );
    }
  }

  Future<void> _deleteCategory(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('delete_category_title'.tr()),
        content: Text(
          'delete_category_msg'.tr(args: [category.name]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('clear'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(apiClientProvider).deleteCategory(category.id);
      refreshCategories(ref);
      refreshEntries(ref);
      refreshAccounts(ref);
      if (!context.mounted) return;
      ToastNotification.show(
        context,
        'category_deleted_msg'.tr(),
        status: ToastStatus.success,
      );
    } catch (e) {
      if (!context.mounted) return;
      ToastNotification.show(
        context,
        '$e',
        status: ToastStatus.error,
      );
    }
  }

  void _showActionsBottomSheet(
    BuildContext context,
    WidgetRef ref,
    CategoryModel category,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text('edit_category'.tr()),
              onTap: () {
                Navigator.of(ctx).pop();
                _openEdit(context, ref, category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text('delete_category'.tr()),
              onTap: () {
                Navigator.of(ctx).pop();
                _deleteCategory(context, ref, category);
              },
            ),
          ],
        ),
      ),
    );
  }
}
