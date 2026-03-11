import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';

import '../../../core/models/budget_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/network/finance_api_client.dart';
import '../../transactions/providers/finance_providers.dart';
import '../../../core/utils/icon_utils.dart';
import '../providers/budget_providers.dart';

class AddBudgetDialog extends ConsumerStatefulWidget {
  final BudgetModel? budgetToEdit;

  // phân biệt budget chi hay income target
  final String categoryType;

  const AddBudgetDialog({
    super.key,
    this.budgetToEdit,
    required this.categoryType,
  });

  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  int? _categoryId;
  late DateTime _selectedMonth;

  bool get _isExpense => widget.categoryType == 'EXPENSE';

  @override
  void initState() {
    super.initState();
    String initialText = '';
    

    _amountController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.budgetToEdit != null && mounted) {  //là edit thì đổ dữ liệu cũ lên form
        final locale = context.locale.toString();
        final formatter = NumberFormat('#,###', locale);
        _amountController.text = formatter.format(widget.budgetToEdit!.amount);
        setState(() {});
      }
    });

    _categoryId = widget.budgetToEdit?.categoryId;
    _selectedMonth = widget.budgetToEdit?.startDate ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
  }

  @override
  void dispose() {  //dọn bộ nhớ khi dialog đóng
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    final locale = context.locale.toString();
    final groupSeparator = NumberFormat('#,###', locale).symbols.GROUP_SEP;
    final decimalSeparator = NumberFormat('#,###', locale).symbols.DECIMAL_SEP;

    final cleanAmount = _amountController.text
        .replaceAll(groupSeparator, '')
        .replaceAll(decimalSeparator, '.');
        
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
      ToastNotification.show(
        context,
        '${'error'.tr()}: $e',
        status: ToastStatus.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final allCategories = categoriesAsync.valueOrNull ?? [];
    final locale = context.locale.toString();

    // lọc category theo loại
    final categories = allCategories
        .where((c) => c.type == widget.categoryType)
        .toList();

    final String addTitle = _isExpense ? 'add_budget_title'.tr() : 'add_target_title'.tr();
    final String editTitle = _isExpense ? 'edit_budget_title'.tr() : 'edit_target_title'.tr();
    final String amountHint = _isExpense ? 'expense_budget'.tr() : 'income_target'.tr();

    return AlertDialog(
      title: Text(widget.budgetToEdit == null ? addTitle : editTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: _categoryId,
                decoration: InputDecoration(labelText: 'category_label'.tr()),
                items: categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              IconUtils.buildIcon(
                                c.iconName,
                                categoryName: c.name,
                                color: IconUtils.getColor(c.colorHex),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(c.displayName.tr()),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) => v == null ? 'category_required'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: amountHint,
                  suffixText: CurrencyFormatter.getSymbol(context),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {   //tự thêm dấu phân cách hàng nghìn khi user nhập
                  if (value.isEmpty) return;
                  final cleanValue =
                      value.replaceAll(RegExp(r'[^0-9]'), '');
                  if (cleanValue.isEmpty) {
                    _amountController.text = '';
                    return;
                  }
                  
                  final formatter = NumberFormat('#,###', locale);
                  final formatted = formatter.format(int.parse(cleanValue));

                  if (_amountController.text != formatted) {
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection:
                          TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'amount_required'.tr();
                  
                  final groupSeparator = NumberFormat('#,###', locale).symbols.GROUP_SEP;
                  final decimalSeparator = NumberFormat('#,###', locale).symbols.DECIMAL_SEP;
                  
                  final cleanValue = v
                      .replaceAll(groupSeparator, '')
                      .replaceAll(decimalSeparator, '.');
                      
                  if ((double.tryParse(cleanValue) ?? 0) <= 0) {
                    return 'amount_invalid'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text('month_label'.tr()),
                subtitle:
                    Text(DateFormat('MM/yyyy', locale).format(_selectedMonth)),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedMonth,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedMonth =
                        DateTime(picked.year, picked.month, 1));
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr())),
        ElevatedButton(onPressed: _save, child: Text('save'.tr())),
      ],
    );
  }
}
