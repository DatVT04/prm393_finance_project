import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import '../../../core/models/budget_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/network/finance_api_client.dart';
import '../../transactions/providers/finance_providers.dart';
import '../providers/budget_providers.dart';

class AddBudgetDialog extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;
  const AddBudgetDialog({super.key, this.budgetToEdit});

  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  int? _categoryId;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    String initialText = '';
    if (widget.budgetToEdit != null) {
      final formatter = NumberFormat('#,###', 'vi_VN');
      initialText = formatter.format(widget.budgetToEdit!.amount).replaceAll(',', '.');
    }
    _amountController = TextEditingController(text: initialText);
    _categoryId = widget.budgetToEdit?.categoryId;
    _selectedMonth = widget.budgetToEdit?.startDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    final cleanAmount = _amountController.text.replaceAll('.', '');
    final amount = double.tryParse(cleanAmount) ?? 0;
    final start = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final end = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    final budget = BudgetModel(
      id: widget.budgetToEdit?.id,
      categoryId: _categoryId!,
      amount: amount,
      startDate: start,
      endDate: end,
    );

    try {
      await ref.read(apiClientProvider).upsertBudget(budget);
      if (!mounted) return;
      refreshBudgets(ref);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ?? [];

    return AlertDialog(
      title: Text(widget.budgetToEdit == null ? 'add_budget_title'.tr() == 'add_budget_title' ? 'Thiết lập ngân sách' : 'add_budget_title'.tr() : 'edit_budget_title'.tr() == 'edit_budget_title' ? 'Sửa ngân sách' : 'edit_budget_title'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: InputDecoration(labelText: 'category_label'.tr()),
                items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'amount_label'.tr(),
                  suffixText: 'đ',
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isEmpty) return;
                  // Remove any non-digits
                  final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue.isEmpty) {
                    _amountController.text = '';
                    return;
                  }
                  final formatter = NumberFormat('#,###', 'vi_VN');
                  final formatted = formatter.format(int.parse(cleanValue)).replaceAll(',', '.');
                  
                  if (_amountController.text != formatted) {
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập số tiền';
                  final cleanValue = v.replaceAll('.', '');
                  if ((double.tryParse(cleanValue) ?? 0) <= 0) return 'Số tiền không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('month_label'.tr() == 'month_label' ? 'Tháng áp dụng' : 'month_label'.tr()),
                subtitle: Text(DateFormat('MM/yyyy').format(_selectedMonth)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                   // A simpler month picker
                   final picked = await showDatePicker(
                     context: context,
                     initialDate: _selectedMonth,
                     firstDate: DateTime.now().subtract(const Duration(days: 365)),
                     lastDate: DateTime.now().add(const Duration(days: 365)),
                   );
                   if (picked != null) {
                     setState(() => _selectedMonth = DateTime(picked.year, picked.month, 1));
                   }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
        ElevatedButton(onPressed: _save, child: Text('save'.tr())),
      ],
    );
  }
}
