import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/services/clipboard_parser.dart';
import 'package:prm393_finance_project/src/core/services/natural_language_parser.dart';
import 'package:prm393_finance_project/src/core/services/receipt_ocr_parser.dart';
import '../providers/finance_providers.dart';
import 'add_entry_modal.dart';

/// Bottom sheet: AI Quick Entry — OCR, Voice/Text, Clipboard.
class AiQuickEntrySheet extends ConsumerStatefulWidget {
  const AiQuickEntrySheet({super.key});

  @override
  ConsumerState<AiQuickEntrySheet> createState() => _AiQuickEntrySheetState();
}

class _AiQuickEntrySheetState extends ConsumerState<AiQuickEntrySheet> {
  final _textController = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;
  String? _clipboardSuggestion;
  double? _clipboardAmount;
  String? _clipboardCategory;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await _getClipboard();
      if (data == null || data.isEmpty) return;
      final suggestion = ClipboardParser.parse(data);
      if (suggestion != null && suggestion.amount > 0) {
        setState(() {
          _clipboardSuggestion = 'Bạn vừa copy giao dịch ${_formatMoney(suggestion.amount)}';
          _clipboardAmount = suggestion.amount;
          _clipboardCategory = suggestion.suggestedCategoryName;
        });
      }
    } catch (_) {}
  }

  Future<String?> _getClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (_) {
      return null;
    }
  }

  String _formatMoney(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}tr';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toInt().toString();
  }

  Future<void> _pickReceiptAndOcr() async {
    // ML Kit OCR hiện chỉ hỗ trợ Android / iOS trong app này.
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    if (!isMobile) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OCR hiện chỉ hỗ trợ trên Android / iOS. Vui lòng thử trên điện thoại.'),
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null || !mounted) return;
    Navigator.of(context).pop();
    try {
      final inputImage = InputImage.fromFilePath(x.path);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();
      final text = result.text;
      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không nhận diện được chữ trên ảnh')),
          );
        }
        return;
      }
      final ocrResult = ReceiptOcrParser.parse(text);
      _openAddEntryFromOcr(ocrResult);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi OCR: $e')),
        );
      }
    }
  }

  void _openAddEntryFromOcr(ReceiptOcrResult ocr) async {
    List<CategoryModel> list;
    try {
      list = await ref.read(apiClientProvider).getCategories();
    } catch (_) {
      list = [];
    }
    int? categoryId;
    for (final c in list) {
      if (c.name == 'Ăn uống') {
        categoryId = c.id;
        break;
      }
    }
    if (categoryId == null && list.isNotEmpty) categoryId = list.first.id;
    final amount = ocr.totalAmount ?? 0.0;
    final note = [if (ocr.storeName != null) ocr.storeName!, ocr.rawText].join('\n');
    final date = ocr.date;
    final prefill = AddEntryInput(
      amount: amount > 0 ? amount : null,
      categoryId: categoryId,
      note: note.isNotEmpty ? note : null,
      source: 'OCR',
    );
    if (!mounted) return;
    _openAddModal(prefill, initialDate: date);
  }

  void _openAddModal(AddEntryInput prefill, {DateTime? initialDate}) {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddEntryModal(prefill: prefill),
    );
  }

  void _startListening() async {
    final available = await _speech.initialize();
    if (!available || !mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        if (mounted) _textController.text = result.recognizedWords;
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'vi_VN',
    );
  }

  void _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _listening = false);
  }

  void _submitNaturalText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final parsed = NaturalLanguageParser.parse(text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy số tiền. Thử "Ăn phở 50k" hoặc "100.000"')),
      );
      return;
    }
    List<CategoryModel> list;
    try {
      list = await ref.read(apiClientProvider).getCategories();
    } catch (_) {
      list = [];
    }
    int? categoryId;
    for (final c in list) {
      if (c.name == (parsed.suggestedCategoryName ?? '')) {
        categoryId = c.id;
        break;
      }
    }
    if (categoryId == null && list.isNotEmpty) categoryId = list.first.id;
    if (!mounted) return;
    Navigator.of(context).pop();
    _openAddModal(AddEntryInput(
      amount: parsed.amount,
      categoryId: categoryId,
      note: parsed.note,
      source: 'VOICE',
    ));
  }

  void _useClipboardSuggestion() async {
    if (_clipboardAmount == null) return;
    List<CategoryModel> list;
    try {
      list = await ref.read(apiClientProvider).getCategories();
    } catch (_) {
      list = [];
    }
    int? categoryId;
    for (final c in list) {
      if (c.name == (_clipboardCategory ?? '')) {
        categoryId = c.id;
        break;
      }
    }
    if (categoryId == null && list.isNotEmpty) categoryId = list.first.id;
    if (!mounted) return;
    Navigator.of(context).pop();
    _openAddModal(AddEntryInput(
      amount: _clipboardAmount!,
      categoryId: categoryId,
      note: 'Từ clipboard',
      source: 'CLIPBOARD',
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Nhập nhanh bằng AI',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_clipboardSuggestion != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.content_paste),
                title: Text(_clipboardSuggestion!),
                subtitle: _clipboardCategory != null ? Text('Gợi ý: $_clipboardCategory') : null,
                trailing: FilledButton(
                  onPressed: _useClipboardSuggestion,
                  child: const Text('Lưu'),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          OutlinedButton.icon(
            onPressed: _pickReceiptAndOcr,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp hóa đơn (OCR)'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'Nói hoặc gõ: "Ăn phở 50k", "Đổ xăng 100k"',
              border: const OutlineInputBorder(),
              suffixIcon: _listening
                  ? IconButton(
                      icon: const Icon(Icons.stop),
                      onPressed: _stopListening,
                    )
                  : IconButton(
                      icon: const Icon(Icons.mic),
                      onPressed: _startListening,
                    ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _submitNaturalText,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Tạo ghi chú từ nội dung trên'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
