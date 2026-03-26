import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:prm393_finance_project/src/core/constants/api_constants.dart';

import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';
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
  final String locale;
  CurrencyInputFormatter({required this.locale});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(text);
    final formatter = NumberFormat('#,###', locale);
    final newText = formatter.format(value);

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
  String? _locationName;
  bool _resolvingLocation = false;
  bool _saving = false;

  String _stripNoteMeta(String input) {
    if (input.isEmpty) return '';
    final normalized = input.replaceAll('\r\n', '\n');
    final lines = normalized.split('\n');
    var end = lines.length;
    while (end > 0) {
      final line = lines[end - 1].trimRight();
      if (line.isEmpty) {
        end--;
        continue;
      }
      if (line == '📷 Ảnh đính kèm' || line.startsWith('📍 ')) {
        end--;
        continue;
      }
      break;
    }
    final cleaned = lines.take(end).toList();
    return cleaned.join('\n').trimRight();
  }

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    final e = widget.entryToEdit;
    if (e != null) {
      _initialAmount = e.amount;
      _selectedCategoryId = e.categoryId;
      if (e.note != null && e.note!.isNotEmpty) {
        final noteRaw = _stripNoteMeta(e.note!);
        _noteController.text = noteRaw;
      }
      _selectedDate = e.transactionDate;
      _selectedAccountId = e.accountId;
      _selectedType = e.type;
      _existingImageUrl = e.imageUrl;
      _latitude = e.latitude;
      _longitude = e.longitude;
      _locationName = e.locationName;
      if (_latitude != null && _longitude != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_locationName == null) {
            _resolveLocationName(_latitude!, _longitude!, showError: false);
          }
        });
      }
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
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'choose_image_source'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('gallery'.tr()),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text('camera'.tr()),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      final picker = ImagePicker();
      final x = await picker.pickImage(source: source);
      if (x != null) {
        setState(() {
          _imagePath = x.path;
          _imageFile = x;
        });
      }
    }
  }

  String? _formatPlacemark(Placemark p) {
    final parts = <String?>[
      p.name,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.country,
    ];
    final seen = <String>{};
    final filtered = <String>[];
    for (final part in parts) {
      final value = (part ?? '').trim();
      if (value.isEmpty) continue;
      if (seen.add(value)) {
        filtered.add(value);
      }
    }
    if (filtered.isEmpty) return null;
    return filtered.join(', ');
  }

  Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final name = _formatPlacemark(placemarks.first);
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {
      // Fallback
    }

    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {'User-Agent': 'FinanceApp/1.0.0'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data['display_name'];
        if (displayName != null) {
          return displayName as String;
        }
      }
    } catch (_) {
      // ignore
    }
    return null;
  }

  Future<void> _resolveLocationName(
    double lat,
    double lon, {
    bool showError = true,
  }) async {
    if (_resolvingLocation) return;
    setState(() => _resolvingLocation = true);
    final name = await _reverseGeocode(lat, lon);
    if (!mounted) return;
    setState(() {
      _locationName = name;
      _resolvingLocation = false;
    });
    if (showError && name == null) {
      ToastNotification.show(
        context,
        'location_name_unavailable'.tr(),
        status: ToastStatus.warning,
      );
    }
  }

  Future<void> _pickLocation() async {
    final ok = await Geolocator.isLocationServiceEnabled();
    if (!ok) {
      if (mounted) {
        ToastNotification.show(
          context,
          'enable_location_msg'.tr(),
          status: ToastStatus.warning,
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ToastNotification.show(
            context,
            'Quyền truy cập vị trí bị từ chối.',
            status: ToastStatus.error,
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ToastNotification.show(
          context,
          'Vui lòng vào Cài đặt để cấp quyền vị trí cho ứng dụng.',
          status: ToastStatus.error,
        );
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
        _locationName = null;
      });
      await _resolveLocationName(pos.latitude, pos.longitude);
    } catch (e) {
      if (mounted) {
        ToastNotification.show(
          context,
          '${'error_getting_location'.tr()}: $e',
          status: ToastStatus.error,
        );
      }
    }
  }

  double? _parseAmount(String s) {
    final locale = context.locale.toString();
    final groupSeparator = NumberFormat('#,###', locale).symbols.GROUP_SEP;
    s = s.trim().replaceAll(groupSeparator, '').replaceAll(',', '.').replaceAll(' ', '');
    // If it ends with k or tr after removing separators
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
      ToastNotification.show(
        context,
        'category_required'.tr(),
        status: ToastStatus.warning,
      );
      return;
    }
    if (_selectedAccountId == null) {
      ToastNotification.show(
        context,
        'account_required'.tr(),
        status: ToastStatus.warning,
      );
      return;
    }

    final amount = _parseAmount(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ToastNotification.show(
        context,
        'amount_invalid'.tr(),
        status: ToastStatus.warning,
      );
      return;
    }

    setState(() => _saving = true);
    final note = _stripNoteMeta(_noteController.text).trim();
    var noteWithMeta = note;
    final hasImage = _imagePath != null || _existingImageUrl != null;
    if (hasImage) {
      noteWithMeta += (note.isEmpty ? '' : '\n') + '📷 Ảnh đính kèm';
    }
    if (_latitude != null && _longitude != null) {
      final locationText = (_locationName != null && _locationName!.trim().isNotEmpty)
          ? _locationName!
          : '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}';
      noteWithMeta += (noteWithMeta.isEmpty ? '' : '\n') + '📍 $locationText';
    }


    final entry = FinancialEntryModel(
      id: 0,
      amount: amount,
      note: noteWithMeta.isEmpty ? null : noteWithMeta,
      categoryId: _selectedCategoryId!,
      accountId: _selectedAccountId!,
      type: _selectedType,
      transactionDate: _selectedDate,
      imageUrl: _imagePath == null ? _existingImageUrl : null,
      latitude: _latitude,
      longitude: _longitude,
      locationName: _locationName,
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
      ToastNotification.show(
        context,
        'entry_saved_msg'.tr(),
        status: ToastStatus.success,
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
        ToastNotification.show(
          context,
          'Lỗi: $msg',
          status: ToastStatus.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesWithRefreshProvider);
    final theme = Theme.of(context);
    final locale = context.locale.toString();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                const SizedBox(height: 24),
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
                      final categories = ref.read(categoriesProvider).value;
                      if (categories != null && categories.isNotEmpty) {
                        final filtered = categories.where((c) => c.type == _selectedType).toList();
                        if (filtered.isNotEmpty) {
                          _selectedCategoryId = filtered.first.id;
                        } else {
                          _selectedCategoryId = null;
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'amount_label'.tr(),
                    prefixIcon: const Icon(Icons.attach_money),
                    suffixText: CurrencyFormatter.getSymbol(context),
                    border: const OutlineInputBorder(),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(locale: locale),
                  ],
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'amount_required'.tr();
                    final a = _parseAmount(v.trim());
                    if (a == null || a <= 0) return 'amount_invalid'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                categoriesAsync.when(
                  data: (list) {
                    final items = list
                        .where((c) => c.type == _selectedType || c.id == _selectedCategoryId)
                        .toList()
                      ..sort((a, b) {
                        final aIsOther = a.name.toLowerCase().contains('khác');
                        final bIsOther = b.name.toLowerCase().contains('khác');
                        if (aIsOther && !bIsOther) return 1;
                        if (!aIsOther && bIsOther) return -1;
                        return a.name.compareTo(b.name);
                      });

                    if (_selectedCategoryId == null && items.isNotEmpty) {
                      _selectedCategoryId = items.first.id;
                    }

                    final selectedValue = items.any((c) => c.id == _selectedCategoryId) 
                        ? _selectedCategoryId 
                        : (items.isEmpty 
                            ? (list.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null) 
                            : items.first.id);

                    return DropdownButtonFormField<int>(
                      value: selectedValue,
                      decoration: InputDecoration(
                        labelText: 'category_label'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: items
                          .map(
                            (c) => DropdownMenuItem<int>(
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
                                  Text(
                                    (c.name.toLowerCase() == 'khác' || c.name.toLowerCase() == 'other') ? c.name.tr() : c.name,
                                  ),
                                ],
                              ),
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
                const SizedBox(height: 24),
                ref
                    .watch(allAccountsProvider)
                    .when(
                      data: (list) {
                        // Rule 2 & 5: When creating new, only show active wallets.
                        // Rule 4: When editing, only show active wallets + the current one if it's deleted.
                        final dropdownItems = list.where((a) {
                          if (!a.isDeleted) return true;
                          // Rule 4: The deleted wallet should appear only as the currently selected value.
                          return a.id == _selectedAccountId;
                        }).toList();

                        if (_selectedAccountId == null && dropdownItems.isNotEmpty) {
                          _selectedAccountId = dropdownItems.first.id;
                        }

                        return DropdownButtonFormField<int>(
                          value: dropdownItems.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : (dropdownItems.isNotEmpty ? dropdownItems.first.id : null),
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'account_label'.tr(),
                            prefixIcon: const Icon(Icons.account_balance_wallet),
                            border: const OutlineInputBorder(),
                          ),
                          items: dropdownItems
                              .map(
                                (a) => DropdownMenuItem<int>(
                                  value: a.id,
                                  child: Text(
                                    '${a.name}${a.isDeleted ? " (${'deleted_label'.tr()})" : ""} (${CurrencyFormatter.format(context, a.balance)})',
                                    overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 24),
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
                const SizedBox(height: 16),
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
                      onPressed: _pickLocation,
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
                if (_latitude != null && _longitude != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _locationName ??
                                '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_resolvingLocation) const SizedBox(width: 8),
                        if (_resolvingLocation)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
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
                      lastDate: DateTime.now(),
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
      ),
    );
  }
}
