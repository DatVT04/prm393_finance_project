import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final String locale;
  CurrencyInputFormatter({required this.locale});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    
    double value = double.parse(text);
    final formatter = NumberFormat('#,###', locale);
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AddAccountModal extends ConsumerStatefulWidget {
  /// Nếu có thì đang sửa; null thì thêm mới.
  final AccountModel? accountToEdit;

  const AddAccountModal({super.key, this.accountToEdit});

  @override
  ConsumerState<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends ConsumerState<AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  bool _saving = false;

  String? _selectedIconName;
  String? _selectedColorHex;

  final List<Map<String, dynamic>> _icons = [
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet},
    {'name': 'account_balance', 'icon': Icons.account_balance},
    {'name': 'credit_card', 'icon': Icons.credit_card},
    {'name': 'savings', 'icon': Icons.savings},
    {'name': 'payments', 'icon': Icons.payments},
    {'name': 'wallet', 'icon': Icons.wallet},
    {'name': 'money', 'icon': Icons.money},
    {'name': 'attach_money', 'icon': Icons.attach_money},
  ];

  final List<String> _colors = [
    '#F44336', // Red
    '#E91E63', // Pink
    '#9C27B0', // Purple
    '#673AB7', // Deep Purple
    '#3F51B5', // Indigo
    '#2196F3', // Blue
    '#03A9F4', // Light Blue
    '#00BCD4', // Cyan
    '#009688', // Teal
    '#4CAF50', // Green
    '#8BC34A', // Light Green
    '#CDDC39', // Lime
    '#FFEB3B', // Yellow
    '#FFC107', // Amber
    '#FF9800', // Orange
    '#FF5722', // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final a = widget.accountToEdit;
      final locale = context.locale.toString();
      if (a != null) {
        _nameController.text = a.name;
        _balanceController.text = NumberFormat('#,###', locale).format(a.balance);
        _selectedIconName = a.iconName;
        _selectedColorHex = a.colorHex;
      } else {
        _selectedIconName = 'account_balance_wallet';
        _selectedColorHex = '#2196F3';
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final locale = context.locale.toString();
      final groupSeparator = NumberFormat('#,###', locale).symbols.GROUP_SEP;
      final decimalSeparator = NumberFormat('#,###', locale).symbols.DECIMAL_SEP;
      
      final name = _nameController.text.trim();
      final balanceStr = _balanceController.text.trim()
          .replaceAll(' ', '')
          .replaceAll(groupSeparator, '')
          .replaceAll(decimalSeparator, '.');
          
      final balance = double.tryParse(balanceStr) ?? 0.0;
      final editing = widget.accountToEdit;

      if (editing != null) {
        await ref.read(apiClientProvider).updateAccount(
          editing.id,
          name,
          balance,
          iconName: _selectedIconName,
          colorHex: _selectedColorHex,
        );
      } else {
        await ref.read(apiClientProvider).createAccount(
          name,
          balance,
          iconName: _selectedIconName,
          colorHex: _selectedColorHex,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ToastNotification.show(
        context,
        e.toString(),
        status: ToastStatus.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = IconUtils.getColor(_selectedColorHex);
    final locale = context.locale.toString();
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.accountToEdit != null ? 'edit_account_title'.tr() : 'add_account_title'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'account_name_label'.tr(),
                  hintText: 'account_name_hint'.tr(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'name_required'.tr() : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'initial_balance_label'.tr(),
                  hintText: '0',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixText: CurrencyFormatter.getSymbol(context),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(locale: locale),
                ],
              ),
              const SizedBox(height: 24),
              Text('choose_icon'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = _icons[index];
                    final isSelected = _selectedIconName == item['name'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIconName = item['name']),
                      child: Container(
                        width: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? color : Colors.transparent,
                          ),
                        ),
                        child: Icon(
                          item['icon'],
                          color: isSelected ? color : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text('choose_color'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((hex) {
                  final isSelected = _selectedColorHex == hex;
                  final itemColor = IconUtils.getColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorHex = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: itemColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: itemColor.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: color,
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(widget.accountToEdit != null ? 'update'.tr() : 'save_account'.tr()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
