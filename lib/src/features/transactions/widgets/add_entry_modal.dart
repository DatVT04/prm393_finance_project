import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
  final String? source;
  AddEntryInput({this.amount, this.categoryId, this.note, this.source});
}

class AddEntryModal extends ConsumerStatefulWidget {
  const AddEntryModal({
    super.key,
    this.prefill,
  });

  final AddEntryInput? prefill;

  @override
  ConsumerState<AddEntryModal> createState() => _AddEntryModalState();
}

class _AddEntryModalState extends ConsumerState<AddEntryModal> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();
  String? _imagePath;
  double? _latitude;
  double? _longitude;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p != null) {
      if (p.amount != null) _amountController.text = _formatAmount(p.amount!);
      _selectedCategoryId = p.categoryId;
      if (p.note != null && p.note!.isNotEmpty) _noteController.text = p.note!;
    }
  }

  String _formatAmount(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}tr';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toInt().toString();
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
    s = s.trim().replaceAll(',', '.').replaceAll(' ', '');
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
      final created = await client.createEntry(entry);
      if (!mounted) return;
      refreshEntries(ref);
      Navigator.of(context).pop(created);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu ghi chú chi tiêu'), backgroundColor: Colors.green),
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
                'Thêm ghi chú chi tiêu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
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
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _imagePath == null ? _pickImage : null,
                    icon: Icon(_imagePath != null ? Icons.check_circle : Icons.add_photo_alternate),
                    label: Text(_imagePath != null ? 'Đã đính kèm ảnh' : 'Đính kèm ảnh'),
                  ),
                  TextButton.icon(
                    onPressed: _latitude == null ? _pickLocation : null,
                    icon: Icon(_latitude != null ? Icons.location_on : Icons.location_off),
                    label: Text(_latitude != null ? 'Đã thêm vị trí' : 'Thêm vị trí'),
                  ),
                ],
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
