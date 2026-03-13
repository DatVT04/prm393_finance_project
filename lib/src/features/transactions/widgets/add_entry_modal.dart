import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
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
  AddEntryInput({this.amount, this.categoryId, this.note, this.type, this.source});
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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
    final formatter = NumberFormat('#,###', 'vi_VN');
    String newText = formatter.format(value);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AddEntryModal extends ConsumerStatefulWidget {
  const AddEntryModal({
    super.key,
    this.prefill,
    this.entryToEdit,
  });

  final AddEntryInput? prefill;
  final FinancialEntryModel? entryToEdit;

  @override
  ConsumerState<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends ConsumerState<AddEntryModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int? _selectedCategoryId;
  int? _selectedAccountId;
  String _selectedType = 'EXPENSE'; // INCOME, EXPENSE, TRANSFER
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
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
      _amountController.text = _formatAmount(e.amount);
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
      if (p.amount != null) _amountController.text = _formatAmount(p.amount!);
      _selectedCategoryId = p.categoryId;
      if (p.note != null && p.note!.isNotEmpty) _noteController.text = p.note!;
      if (p.type != null) _selectedType = p.type!;
    }
  }

  String _formatAmount(double v) {
    // If it's a "clean" number, we can still use k/tr for initial display if we want,
    // but for the controller with formatter, we should probably use the dotted format.
    final formatter = NumberFormat('#,###', 'vi_VN');
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
    if (x != null) setState(() => _imagePath = x.path);
  }

  Future<void> _pickLocation() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng bật định vị')),
        );
      }
      return;
    }
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không lấy được vị trí: $e')),
        );
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
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tài khoản')),
      );
      return;
    }

    final amount = _parseAmount(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số tiền không hợp lệ')),
      );
      return;
    }

    setState(() => _saving = true);
    final note = _noteController.text.trim();
    var noteWithMeta = note;
    if (_imagePath != null) noteWithMeta += (note.isEmpty ? '' : '\n') + '📷 Ảnh đính kèm';
    if (_latitude != null && _longitude != null) {
      noteWithMeta += (noteWithMeta.isEmpty ? '' : '\n') + '📍 $_latitude, $_longitude';
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
      imageUrl: null, // local path not sent to server; note has "📷 Ảnh đính kèm"
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
        await client.uploadImage(result.id, _imagePath!);
      }

      if (!mounted) return;
      refreshEntries(ref);
      Navigator.of(context).pop(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ghi chú'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
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
                widget.entryToEdit != null ? 'Sửa ghi chú' : 'Thêm ghi chú chi tiêu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'EXPENSE', label: Text('Chi'), icon: Icon(Icons.remove_circle_outline)),
                  ButtonSegment(value: 'INCOME', label: Text('Thu'), icon: Icon(Icons.add_circle_outline)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (val) => setState(() => _selectedType = val.first),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  helperText: 'Ví dụ: 50k, 1.5tr, 50000',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.ktr]')),
                  CurrencyInputFormatter(),
                ],
                keyboardType: TextInputType.text,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final a = _parseAmount(v.trim());
                  if (a == null || a <= 0) return 'Số tiền không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (list) {
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Danh mục',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: list
                        .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Không tải được danh mục'),
              ),
              const SizedBox(height: 16),
              ref.watch(accountsProvider).when(
                data: (list) {
                  if (_selectedAccountId == null && list.isNotEmpty) {
                    _selectedAccountId = list.first.id;
                  }
                  return DropdownButtonFormField<int>(
                    value: _selectedAccountId,
                    decoration: const InputDecoration(
                      labelText: 'Tài khoản/Ví',
                      prefixIcon: Icon(Icons.account_balance_wallet),
                      border: OutlineInputBorder(),
                    ),
                    items: list
                        .map((a) => DropdownMenuItem<int>(value: a.id, child: Text('${a.name} (${NumberFormat('#,###', 'vi').format(a.balance)}đ)')))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedAccountId = v),
                    validator: (v) => v == null ? 'Vui lòng chọn tài khoản' : null,
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Không tải được tài khoản'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (có thể dùng #tag và @mention)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
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
                    onPressed: (_imagePath == null && _existingImageUrl == null) ? _pickImage : () {
                      setState(() {
                        _imagePath = null;
                        _existingImageUrl = null;
                      });
                    },
                    icon: Icon((_imagePath != null || _existingImageUrl != null) ? Icons.cancel : Icons.add_photo_alternate),
                    label: Text((_imagePath != null || _existingImageUrl != null) ? 'Xóa ảnh' : 'Đính kèm ảnh'),
                  ),
                  TextButton.icon(
                    onPressed: _latitude == null ? _pickLocation : null,
                    icon: Icon(_latitude != null ? Icons.location_on : Icons.location_off),
                    label: Text(_latitude != null ? 'Đã thêm vị trí' : 'Thêm vị trí'),
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
                            child: Image.file(File(_imagePath!)),
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
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
                            child: Image.network('${ApiConstants.baseUrl}$_existingImageUrl'),
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
                    locale: const Locale('vi', 'VN'),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Ngày',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Lưu ghi chú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
