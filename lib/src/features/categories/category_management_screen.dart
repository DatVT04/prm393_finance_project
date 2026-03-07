import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';

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
        title: const Text('Xóa danh mục'),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}"? Các ghi chú đang dùng danh mục này có thể bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(apiClientProvider).deleteCategory(category.id);
      refreshCategories(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa danh mục'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
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
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật danh mục'), backgroundColor: Colors.green),
        );
      } else {
        await client.createCategory(result);
        refreshCategories(ref);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm danh mục'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithRefreshProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
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
                    'Chưa có danh mục nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nhấn nút (+) để thêm',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final c = list[index];
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
                    backgroundColor: _parseColor(c.colorHex).withOpacity(0.2),
                    child: _buildIcon(c),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.type == 'INCOME' ? 'Thu nhập' : 'Chi tiêu',
                        style: TextStyle(
                          color: c.type == 'INCOME' ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (c.sortOrder != null) Text('Thứ tự: ${c.sortOrder}'),
                    ],
                  ),
                  trailing: Row(
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
              const Text(
                'Không tải được danh mục.\nKiểm tra backend đã chạy.',
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

  Widget _buildIcon(CategoryModel category) {
    final color = _parseColor(category.colorHex);
    final name = category.iconName;
    if (name == null || name.isEmpty) {
      return Icon(Icons.category, color: color);
    }
    IconData icon;
    switch (name) {
      case 'utensils':
        icon = FontAwesomeIcons.utensils;
        break;
      case 'cartShopping':
        icon = FontAwesomeIcons.cartShopping;
        break;
      case 'moneyBillWave':
        icon = FontAwesomeIcons.moneyBillWave;
        break;
      case 'sackDollar':
        icon = FontAwesomeIcons.sackDollar;
        break;
      case 'piggyBank':
        icon = FontAwesomeIcons.piggyBank;
        break;
      case 'wallet':
        icon = FontAwesomeIcons.wallet;
        break;
      case 'film':
        icon = FontAwesomeIcons.film;
        break;
      case 'gamepad':
        icon = FontAwesomeIcons.gamepad;
        break;
      case 'heartbeat':
        icon = FontAwesomeIcons.heartPulse;
        break;
      case 'hospital':
        icon = FontAwesomeIcons.hospital;
        break;
      case 'stethoscope':
        icon = FontAwesomeIcons.stethoscope;
        break;
      case 'graduationCap':
        icon = FontAwesomeIcons.graduationCap;
        break;
      case 'bus':
        icon = FontAwesomeIcons.bus;
        break;
      case 'car':
        icon = FontAwesomeIcons.car;
        break;
      case 'motorcycle':
        icon = FontAwesomeIcons.motorcycle;
        break;
      case 'house':
        icon = FontAwesomeIcons.house;
        break;
      case 'lightbulb':
        icon = FontAwesomeIcons.lightbulb;
        break;
      case 'gift':
        icon = FontAwesomeIcons.gift;
        break;
      case 'plane':
        icon = FontAwesomeIcons.plane;
        break;
      case 'coffee':
        icon = FontAwesomeIcons.mugSaucer;
        break;
      default:
        icon = Icons.category;
    }
    return FaIcon(icon, color: color, size: 20);
  }
}
