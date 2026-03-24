import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';

class AddAccountModal extends ConsumerStatefulWidget {
  /// Nếu có thì đang sửa; null thì thêm mới.
  final AccountModel? accountToEdit;

  const AddAccountModal({super.key, this.accountToEdit});

  @override
  ConsumerState<AddAccountModal> createState() => _AddAccountModalState();
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');
    
    double value = double.parse(text);
    final formatter = NumberFormat('#,###', 'vi_VN');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class _AddAccountModalState extends ConsumerState<AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.accountToEdit;
    if (a != null) {
      _nameController.text = a.name;
      _balanceController.text = NumberFormat('#,###', 'vi_VN').format(a.balance);
    }
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
      final name = _nameController.text.trim();
      final balanceStr = _balanceController.text.trim().replaceAll(' ', '').replaceAll('.', '').replaceAll(',', '.');
      final balance = double.tryParse(balanceStr) ?? 0.0;
      final editing = widget.accountToEdit;

      if (editing != null) {
        await ref.read(apiClientProvider).updateAccount(editing.id, name, balance);
      } else {
        await ref.read(apiClientProvider).createAccount(name, balance);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.accountToEdit != null ? 'Sửa tài khoản' : 'Thêm tài khoản mới',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên ví / Tài khoản',
                hintText: 'Ví dụ: Ví tiền mặt, Ngân hàng VCB...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số dư ban đầu',
                hintText: '0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                // No need to check double.tryParse here because digitsOnly + formatter ensures format
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(widget.accountToEdit != null ? 'Cập nhật' : 'Lưu tài khoản'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
