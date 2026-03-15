import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';

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
    final nameController = TextEditingController(text: existing?.name ?? '');
    final iconController = TextEditingController(text: existing?.iconName ?? '');
    final colorController = TextEditingController(text: existing?.colorHex ?? '');
    final sortController = TextEditingController(
      text: existing?.sortOrder != null ? '${existing!.sortOrder}' : '',
    );

    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing != null ? 'Sửa danh mục' : 'Thêm danh mục',
                style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên danh mục *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(
                  labelText: 'Icon (tên Material Icons, tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: colorController,
                decoration: const InputDecoration(
                  labelText: 'Màu hex (vd: #006D5B, tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Thứ tự sắp xếp (số, tùy chọn)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tên danh mục')),
                          );
                          return;
                        }
                        final sortOrder = int.tryParse(sortController.text.trim());
                        final category = CategoryModel(
                          id: existing?.id ?? 0,
                          name: name,
                          iconName: iconController.text.trim().isEmpty
                              ? null
                              : iconController.text.trim(),
                          colorHex: colorController.text.trim().isEmpty
                              ? null
                              : colorController.text.trim(),
                          sortOrder: sortOrder,
                        );
                        Navigator.of(ctx).pop(category);
                      },
                      child: Text(existing != null ? 'Lưu' : 'Thêm'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
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
                    child: Icon(
                      _iconFromName(c.iconName),
                      color: _parseColor(c.colorHex),
                    ),
                  ),
                  title: Text(
                    c.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: c.sortOrder != null
                      ? Text('Thứ tự: ${c.sortOrder}')
                      : null,
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

  IconData _iconFromName(String? name) {
    if (name == null || name.isEmpty) return Icons.category;
    switch (name.toLowerCase()) {
      case 'restaurant':
        return Icons.restaurant;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'confirmation_number':
        return Icons.confirmation_number;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'local_parking':
        return Icons.local_parking;
      default:
        return Icons.category;
    }
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
}
