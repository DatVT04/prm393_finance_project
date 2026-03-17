import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/services/clipboard_parser.dart';
import 'package:prm393_finance_project/src/core/services/natural_language_parser.dart';
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
          _clipboardSuggestion = '${'clipboard_suggestion_prefix'.tr()} ${_formatMoney(suggestion.amount)}';
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

  void _openAddModal(AddEntryInput prefill, {DateTime? initialDate}) {
    // Kept for backward compatibility with existing calls.
    _openAddModalAwaitable(prefill, initialDate: initialDate);
  }

  Future<FinancialEntryModel?> _openAddModalAwaitable(
    AddEntryInput prefill, {
    DateTime? initialDate,
    FinancialEntryModel? entryToEdit,
  }) {
    return showModalBottomSheet<FinancialEntryModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddEntryModal(
        prefill: prefill,
        entryToEdit: entryToEdit,
      ),
    );
  }

  void _startListening() async {
    final available = await _speech.initialize(
      onStatus: (_) {},
      onError: (_) {},
    );
    if (!mounted) return;
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể truy cập micro. Hãy cấp quyền ghi âm (Microphone) cho ứng dụng.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
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
    final parsedList = NaturalLanguageParser.parseMultiple(text);
    if (parsedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('no_amount_found_msg'.tr())),
      );
      return;
    }

    if (parsedList.length == 1) {
      // Giữ hành vi cũ với 1 giao dịch.
      await _openSingleFromParsed(parsedList.first, source: 'VOICE');
    } else {
      // Nhiều giao dịch: mở màn xem trước, cho chọn, rồi lần lượt vào form chi tiết.
      await _openMultiEntriesPreview(parsedList);
    }
  }

  Future<FinancialEntryModel?> _openSingleFromParsed(
    ParsedQuickEntry parsed, {
    required String source,
  }) async {
    List<CategoryModel> categories;
    try {
      categories = await ref.read(apiClientProvider).getCategories();
    } catch (_) {
      categories = [];
    }
    int? categoryId;
    for (final c in categories) {
      if (c.name.toLowerCase() == (parsed.suggestedCategoryName ?? '').toLowerCase()) {
        categoryId = c.id;
        break;
      }
    }
    if (categoryId == null && categories.isNotEmpty) categoryId = categories.first.id;

    return _openAddModalAwaitable(AddEntryInput(
      amount: parsed.amount,
      categoryId: categoryId,
      note: parsed.note,
      type: 'EXPENSE',
      source: source,
    ));
  }

  Future<void> _openMultiEntriesPreview(List<ParsedQuickEntry> entries) async {
    if (!mounted) return;

    // Hiển thị sheet danh sách để user tick chọn giao dịch nào muốn lưu.
    final selectedIndexes = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final selected = List<bool>.filled(entries.length, true);
        return StatefulBuilder(
          builder: (ctx, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'review_transactions_title'.tr(),
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'recognized_transactions_msg'.tr(args: [entries.length.toString()]),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        return Material(
                          color: Theme.of(context).dividerColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          child: CheckboxListTile(
                            value: selected[index],
                            onChanged: (v) {
                              setState(() {
                                selected[index] = v ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              '${_formatMoney(e.amount)} đ',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (e.suggestedCategoryName != null)
                                  Text('${'category_suggestion'.tr()}: ${e.suggestedCategoryName}'),
                                if (e.note != null) Text(e.note!),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(<int>[]),
                          child: Text('cancel'.tr()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final chosen = <int>[];
                            for (var i = 0; i < selected.length; i++) {
                              if (selected[i]) chosen.add(i);
                            }
                            Navigator.of(ctx).pop(chosen);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('continue'.tr()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedIndexes == null || selectedIndexes.isEmpty) return;

    final chosenEntries = [
      for (final idx in selectedIndexes) if (idx >= 0 && idx < entries.length) entries[idx],
    ];
    if (chosenEntries.isEmpty || !mounted) return;

    // Đợi 1 nhịp để sheet preview đóng hẳn (tránh race condition trên web/desktop).
    await Future<void>.delayed(const Duration(milliseconds: 150));

    // Sau khi xem trước, lần lượt mở form chi tiết cho từng giao dịch đã chọn.
    for (final e in chosenEntries) {
      if (!mounted) break;
      final saved = await _openSingleFromParsed(e, source: 'VOICE_MULTI');
      // Nếu user đóng/hủy ở giữa thì dừng chuỗi.
      if (saved == null) break;
      refreshEntries(ref);
      refreshAccounts(ref);
    }
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
      note: 'from_clipboard'.tr(),
      type: 'EXPENSE',
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
            'voice_entry_title'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_clipboardSuggestion != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.content_paste),
                title: Text(_clipboardSuggestion!),
                subtitle: _clipboardCategory != null ? Text('${'suggested'.tr()}: $_clipboardCategory') : null,
                trailing: FilledButton(
                  onPressed: _useClipboardSuggestion,
                  child: Text('save'.tr()),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Chỉ còn nhập nhanh bằng giọng nói / văn bản + clipboard,
          // bỏ hoàn toàn chức năng chụp hóa đơn OCR.
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              labelText: 'voice_input_hint'.tr(),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('create_note_from_content'.tr()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
