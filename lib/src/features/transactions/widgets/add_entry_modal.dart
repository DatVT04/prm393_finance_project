import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:prm393_finance_project/src/core/constants/api_constants.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/core/services/note_tag_parser.dart';
import '../providers/finance_providers.dart';

/// Optional prefill from AI Quick Entry (OCR, voice, clipboard).
class AddEntryInput {
  final double? amount;
  final int? categoryId;
  final String? note;
  final String? type;
  final String? source;
  AddEntryInput({
    this.amount,
    this.categoryId,
    this.note,
    this.type,
    this.source,
  });
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Only allow digits and handle specific suffixes 'k', 'tr' if needed,
    // but typically thousand separators are for pure numbers.
    // Here we'll handle pure numbers. If they type k/tr, we might want to let it pass or format after.
    // Let's stick to standard numeric formatting first.
    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(text);
    final formatter = NumberFormat('#,###', newValue.text.isEmpty ? 'vi_VN' : null); // Simple workaround or use a better way to get locale here if possible
    // Actually, inside a formatter it's hard to get context.
    // Let's use a standard format or just digits.
    // Ideally we should pass the locale to the formatter.
    // For now, let's stick to 'vi_VN' or a neutral one.
    String newText = NumberFormat('#,###').format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AddEntryModal extends ConsumerStatefulWidget {
  const AddEntryModal({super.key, this.prefill, this.entryToEdit});

  final AddEntryInput? prefill;
  final FinancialEntryModel? entryToEdit;

  @override
  ConsumerState<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends ConsumerState<AddEntryModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _didInitDependencies = false;
  double? _initialAmount;
  int? _selectedCategoryId;
  int? _selectedAccountId;
  String _selectedType = 'EXPENSE'; // INCOME, EXPENSE, TRANSFER
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  XFile? _imageFile;
  String? _existingImageUrl;
  double? _latitude;
  double? _longitude;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    final e = widget.entryToEdit;
    if (e != null) {
      _initialAmount = e.amount;
      _selectedCategoryId = e.categoryId;
      if (e.note != null && e.note!.isNotEmpty) {
        String noteRaw = e.note!;
        noteRaw = noteRaw.replaceAll(RegExp(r'\r?\n📷 Ảnh đính kèm$'), '');
        noteRaw = noteRaw.replaceAll(RegExp(r'\r?\n📍 .*$'), '');
        _noteController.text = noteRaw;
      }
      _selectedDate = e.transactionDate;
      _selectedAccountId = e.accountId;
      _selectedType = e.type;
      _existingImageUrl = e.imageUrl;
      _latitude = e.latitude;
      _longitude = e.longitude;
    } else if (p != null) {
      _initialAmount = p.amount;
      _selectedCategoryId = p.categoryId;
      if (p.note != null && p.note!.isNotEmpty) _noteController.text = p.note!;
      if (p.type != null) _selectedType = p.type!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDependencies) return;
    if (_initialAmount != null) {
      _amountController.text = _formatAmount(_initialAmount!);
    }
    _didInitDependencies = true;
  }

  String _formatAmount(double v) {
    // If it's a "clean" number, we can still use k/tr for initial display if we want,
    // but for the controller with formatter, we should probably use the dotted format.
    final formatter = NumberFormat('#,###', context.locale.toString());
    return formatter.format(v);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      setState(() {
        _imagePath = x.path;
        _imageFile = x;
      });
    }
  }

  Future<void> _pickLocation() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('enable_location_msg'.tr())));
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'error_getting_location'.tr()}: $e')));
      }
    }
  }

  double? _parseAmount(String s) {
    s = s.trim().replaceAll('.', '').replaceAll(',', '.').replaceAll(' ', '');
    // If it ends with k or tr after removing dots
    if (s.endsWith('k')) {
      final n = double.tryParse(s.substring(0, s.length - 1));
      return n != null ? n * 1000 : null;
    }
    if (s.endsWith('tr')) {
      final n = double.tryParse(s.substring(0, s.length - 2));
      return n != null ? n * 1000000 : null;
    }
    return double.tryParse(s);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == 'INCOME' && _selectedCategoryId == null) {
      final categories = ref.read(categoriesProvider).value;
      if (categories != null && categories.isNotEmpty) {
        final napVi = categories.firstWhere(
          (c) =>
              c.name.toLowerCase().contains('nạp ví') ||
              c.name.toLowerCase().contains('thu nhập'),
          orElse: () => categories.firstWhere(
            (c) => c.name.toLowerCase() == 'khác',
            orElse: () => categories.first,
          ),
        );
        _selectedCategoryId = napVi.id;
      }
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('category_required'.tr())));
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('account_required'.tr())));
      return;
    }

    final amount = _parseAmount(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('amount_invalid'.tr())));
      return;
    }

    setState(() => _saving = true);
    final note = _noteController.text.trim();
    var noteWithMeta = note;
    if (_imagePath != null)
      noteWithMeta += (note.isEmpty ? '' : '\n') + '📷 Ảnh đính kèm';
    if (_latitude != null && _longitude != null) {
      noteWithMeta +=
          (noteWithMeta.isEmpty ? '' : '\n') + '📍 $_latitude, $_longitude';
    }

    final tags = NoteTagParser.extractTags(note);
    final mentions = NoteTagParser.extractMentions(note);

    final entry = FinancialEntryModel(
      id: 0,
      amount: amount,
      note: noteWithMeta.isEmpty ? null : noteWithMeta,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      type: _selectedType,
      transactionDate: _selectedDate,
      tags: tags,
      mentions: mentions,
      imageUrl:
          null, // local path not sent to server; note has "📷 Ảnh đính kèm"
      latitude: _latitude,
      longitude: _longitude,
      source: widget.prefill?.source ?? 'MANUAL',
    );

    try {
      final client = ref.read(apiClientProvider);
      FinancialEntryModel result;
      if (widget.entryToEdit != null) {
        result = await client.updateEntry(widget.entryToEdit!.id, entry);
      } else {
        result = await client.createEntry(entry);
      }

      if (_imagePath != null && !_imagePath!.startsWith('http')) {
        if (kIsWeb && _imageFile != null) {
          final bytes = await _imageFile!.readAsBytes();
          await client.uploadImageBytes(result.id, bytes, _imageFile!.name);
        } else {
          await client.uploadImage(result.id, _imagePath!);
        }
      }

      if (!mounted) return;
      refreshEntries(ref);
      refreshAccounts(ref);
      Navigator.of(context).pop(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('entry_saved_msg'.tr()),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (msg.contains('Số dư ví không đủ')) {
        // Thông báo riêng khi không đủ số dư và cho phép user chọn ví khác
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('insufficient_balance_title'.tr()),
            content: Text('${'insufficient_balance_msg'.tr()}\n\n$msg'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('close'.tr()),
              ),
            ],
          ),
        );
        // Không đóng modal, user có thể đổi ví ngay trên form và lưu lại
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $msg'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithRefreshProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.entryToEdit != null
                    ? 'edit_entry_title'.tr()
                    : 'add_entry_title'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'EXPENSE',
                    label: Text('expense_short'.tr()),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'INCOME',
                    label: Text('income_short'.tr()),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) {
                  final newType = val.first;
                  setState(() {
                    _selectedType = newType;
                    if (_selectedType == 'INCOME') {
                      final categories = ref.read(categoriesProvider).value;
                      if (categories != null && categories.isNotEmpty) {
                        final napVi = categories.firstWhere(
                          (c) =>
                              c.name.toLowerCase().contains('nạp ví') ||
                              c.name.toLowerCase().contains('thu nhập'),
                          orElse: () => categories.firstWhere(
                            (c) => c.name.toLowerCase() == 'khác',
                            orElse: () => categories.first,
                          ),
                        );
                        _selectedCategoryId = napVi.id;
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'amount_label'.tr(),
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                  helperText: 'amount_hint'.tr(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.ktr]')),
                  CurrencyInputFormatter(),
                ],
                keyboardType: TextInputType.text,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'amount_required'.tr();
                  final a = _parseAmount(v.trim());
                  if (a == null || a <= 0) return 'amount_invalid'.tr();
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType != 'INCOME') ...[
                categoriesAsync.when(
                  data: (list) {
                    return DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'category_label'.tr(),
                        prefixIcon: const Icon(Icons.category),
                        border: const OutlineInputBorder(),
                      ),
                      items: list
                          .map(
                            (c) => DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCategoryId = v),
                      validator: (v) =>
                          v == null ? 'category_required'.tr() : null,
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Text('error_loading_categories'.tr()),
                ),
                const SizedBox(height: 16),
              ],
              ref
                  .watch(accountsProvider)
                  .when(
                    data: (list) {
                      if (_selectedAccountId == null && list.isNotEmpty) {
                        _selectedAccountId = list.first.id;
                      }
                      return DropdownButtonFormField<int>(
                        value: _selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'account_label'.tr(),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                          border: const OutlineInputBorder(),
                        ),
                        items: list
                            .map(
                              (a) => DropdownMenuItem<int>(
                                value: a.id,
                                child: Text(
                                  '${a.name} (${NumberFormat('#,###', context.locale.toString()).format(a.balance)}đ)',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedAccountId = v),
                        validator: (v) =>
                            v == null ? 'account_required'.tr() : null,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Text('error_loading_accounts'.tr()),
                  ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'note_label'.tr(),
                  prefixIcon: const Icon(Icons.note),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: (_imagePath == null && _existingImageUrl == null)
                        ? _pickImage
                        : () {
                            setState(() {
                              _imagePath = null;
                              _imageFile = null;
                              _existingImageUrl = null;
                            });
                          },
                    icon: Icon(
                      (_imagePath != null || _existingImageUrl != null)
                          ? Icons.cancel
                          : Icons.add_photo_alternate,
                    ),
                    label: Text(
                      (_imagePath != null || _existingImageUrl != null)
                          ? 'remove_image'.tr()
                          : 'attach_image'.tr(),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _latitude == null ? _pickLocation : null,
                    icon: Icon(
                      _latitude != null
                          ? Icons.location_on
                          : Icons.location_off,
                    ),
                    label: Text(
                      _latitude != null ? 'location_added'.tr() : 'add_location'.tr(),
                    ),
                  ),
                ],
              ),
              if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(8),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: kIsWeb
                                ? Image.network(_imagePath!)
                                : Image.file(File(_imagePath!)),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _imagePath!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(_imagePath!),
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                )
              else if (_existingImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(8),
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              '${ApiConstants.baseUrl}$_existingImageUrl',
                            ),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        '${ApiConstants.baseUrl}$_existingImageUrl',
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    locale: context.locale,
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'date_label'.tr(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy', context.locale.toString()).format(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'save_note'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
