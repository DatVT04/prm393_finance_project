import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:prm393_finance_project/src/core/models/schedule_model.dart';
import 'package:prm393_finance_project/src/features/transactions/providers/finance_providers.dart';
import 'package:prm393_finance_project/src/core/utils/icon_utils.dart';
import 'package:prm393_finance_project/src/shared/widgets/toast_notification.dart';
import 'package:prm393_finance_project/src/shared/utils/currency_formatter.dart';

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


class AddEditScheduleScreen extends ConsumerStatefulWidget {
  final ScheduleModel? scheduleToEdit;
  const AddEditScheduleScreen({super.key, this.scheduleToEdit});

  @override
  ConsumerState<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends ConsumerState<AddEditScheduleScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  int? _selectedAccountId;
  int? _selectedCategoryId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  String _repeatType = 'NONE';
  List<DateTime> _customDates = [];

  String _selectedType = 'EXPENSE';
  bool _typeDetermined = false;
  bool _isLoading = false;

  final List<String> _repeatTypes = ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY', 'CUSTOM'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scheduleToEdit != null) {
        final s = widget.scheduleToEdit!;
        final locale = context.locale.toString();
        _amountController.text = NumberFormat('#,###', locale).format(s.amount);
        _noteController.text = s.note ?? '';
        _selectedAccountId = s.accountId;
        _selectedCategoryId = s.categoryId;
        if (s.type != null) {
          _selectedType = s.type!;
        } else {
          // If type is null (old data), try to find it from categories
          final allCats = ref.read(categoriesProvider).value;
          if (allCats != null) {
            final cat = allCats.firstWhere((c) => c.id == s.categoryId, orElse: () => allCats.first);
            _selectedType = cat.type ?? 'EXPENSE';
          }
        }
        _startDate = s.startDate;
        _repeatType = s.repeatType;
        
        if (_repeatType == 'CUSTOM' && s.repeatConfig != null) {
          try {
            _customDates = s.repeatConfig!.split(',').map((d) => DateTime.parse(d)).toList();
            _customDates.sort((a, b) => a.compareTo(b));
          } catch (e) {
            _customDates = [];
          }
        }
        setState(() {});
      }
    });
  }

  void _updateTypeFromCategory(List<CategoryModel> categories) {
    if (_typeDetermined) return;
    if (widget.scheduleToEdit != null && widget.scheduleToEdit!.type == null) {
       final cat = categories.where((c) => c.id == _selectedCategoryId).firstOrNull;
       if (cat != null && cat.type != null) {
         _typeDetermined = true;
         setState(() {
           _selectedType = cat.type!;
         });
       }
    } else if (widget.scheduleToEdit != null && widget.scheduleToEdit!.type != null) {
       _typeDetermined = true;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    
    // If current _startDate is before tomorrow (could happen if editing an old schedule),
    // use tomorrow as initial date.
    final initialDate = _startDate.isBefore(tomorrow) ? tomorrow : _startDate;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: tomorrow,
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _save() async {
    final locale = context.locale.toString();
    final groupSeparator = NumberFormat('#,###', locale).symbols.GROUP_SEP;
    final amtText = _amountController.text.replaceAll(groupSeparator, '');
    final amount = double.tryParse(amtText);

    if (amount == null || amount <= 0) {
      ToastNotification.show(context, 'amount_invalid'.tr(), status: ToastStatus.error);
      return;
    }
    if (_selectedCategoryId == null) {
      ToastNotification.show(context, 'category_required'.tr(), status: ToastStatus.error);
      return;
    }
    if (_selectedAccountId == null) {
      ToastNotification.show(context, 'account_required'.tr(), status: ToastStatus.error);
      return;
    }

    setState(() => _isLoading = true);

    String? repeatConfig;
    if (_repeatType == 'CUSTOM' && _customDates.isNotEmpty) {
      _customDates.sort((a, b) => a.compareTo(b));
      repeatConfig = _customDates.map((d) => d.toIso8601String()).join(',');
    }

    try {
      final model = ScheduleModel(
        id: widget.scheduleToEdit?.id,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId!,
        amount: amount,
        note: _noteController.text.trim(),
        startDate: _startDate,
        repeatType: _repeatType,
        repeatConfig: repeatConfig,
        type: _selectedType,
      );

      if (widget.scheduleToEdit == null) {
        await ref.read(apiClientProvider).createSchedule(model);
        ToastNotification.show(context, 'schedule_created_success'.tr());
      } else {
        await ref.read(apiClientProvider).updateSchedule(widget.scheduleToEdit!.id!, model);
        ToastNotification.show(context, 'schedule_updated_success'.tr());
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Error: $e', status: ToastStatus.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 24.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final theme = Theme.of(context);
    final locale = context.locale.toString();

    ref.listen(categoriesProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        _updateTypeFromCategory(next.value!);
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(
          widget.scheduleToEdit == null ? 'add_schedule'.tr() : 'edit_schedule'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // AMOUNT
                    _buildSectionHeader('amount_label'.tr(), Icons.attach_money, theme),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _amountController,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                        decoration: InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                          suffixText: CurrencyFormatter.getSymbol(context),
                          suffixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: false),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(locale: locale),
                        ],
                        textAlign: TextAlign.right,
                      ),
                    ),

                    // DETAILS
                    _buildSectionHeader('schedule_details'.tr(), Icons.info_outline, theme),
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
                          // Optional: Clear selection or find first category of new type
                          final categories = ref.read(categoriesProvider).value;
                          if (categories != null) {
                            final filtered = categories.where((c) => c.type == _selectedType).toList();
                            if (filtered.isNotEmpty) {
                              if (!filtered.any((c) => c.id == _selectedCategoryId)) {
                                _selectedCategoryId = filtered.first.id;
                              }
                            }
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Note
                          TextField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: 'note_label'.tr(),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.notes, color: theme.colorScheme.primary, size: 20),
                              ),
                              border: const UnderlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 3,
                            maxLength: 500,
                          ),
                          const SizedBox(height: 16),

                          // Category
                          categoriesAsync.when(
                            data: (list) {
                              // Filter by type
                              final filteredList = list.where((c) => c.type == _selectedType).toList();
                              
                              // Ensure current selected id exists in list, or add it if missing (e.g. deleted)
                              bool exists = filteredList.any((c) => c.id == _selectedCategoryId);
                              return DropdownButtonFormField<int>(
                                value: exists ? _selectedCategoryId : null,
                                decoration: InputDecoration(
                                  labelText: 'category_label'.tr(),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.category, color: Colors.orange, size: 20),
                                  ),
                                  border: const UnderlineInputBorder(),
                                  errorText: (!exists && _selectedCategoryId != null) ? 'category_not_found'.tr() : null,
                                ),
                                icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                                items: [
                                  ...filteredList.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Row(
                                      children: [
                                        IconUtils.buildIcon(
                                          c.iconName,
                                          categoryName: c.name,
                                          size: 20,
                                          color: IconUtils.getColor(c.colorHex),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(c.displayName.tr(), style: const TextStyle(fontSize: 15)),
                                      ],
                                    ),
                                  )),
                                  if (!exists && _selectedCategoryId != null)
                                    DropdownMenuItem(
                                      value: _selectedCategoryId,
                                      enabled: false,
                                      child: Text('deleted_label'.tr(), style: const TextStyle(color: Colors.red)),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _selectedCategoryId = v),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: LinearProgressIndicator(),
                            ),
                            error: (err, _) => Text('error_loading_categories'.tr()),
                          ),
                          const SizedBox(height: 16),

                          // Account
                          accountsAsync.when(
                            data: (list) {
                              bool exists = list.any((a) => a.id == _selectedAccountId);
                              return DropdownButtonFormField<int>(
                                value: exists ? _selectedAccountId : null,
                                decoration: InputDecoration(
                                  labelText: 'account_label'.tr(),
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, color: Colors.green, size: 20),
                                  ),
                                  border: const UnderlineInputBorder(),
                                  errorText: (!exists && _selectedAccountId != null) ? 'account_not_found'.tr() : null,
                                ),
                                icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                                isExpanded: true,
                                items: [
                                  ...list.map((a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text('${a.name} (${CurrencyFormatter.format(context, a.balance)})', style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis),
                                  )),
                                  if (!exists && _selectedAccountId != null)
                                    DropdownMenuItem(
                                      value: _selectedAccountId,
                                      enabled: false,
                                      child: Text('deleted_label'.tr(), style: const TextStyle(color: Colors.red)),
                                    ),
                                ],
                                onChanged: (v) => setState(() => _selectedAccountId = v),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: LinearProgressIndicator(),
                            ),
                            error: (err, _) => Text('error_loading_accounts'.tr()),
                          ),
                        ],
                      ),
                    ),

                    // SCHEDULE SETTINGS
                    _buildSectionHeader('schedule_settings'.tr(), Icons.schedule, theme),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.calendar_month, color: Colors.blue, size: 20),
                            ),
                            title: Text('date_label'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                            subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(_startDate),
                              style: TextStyle(fontSize: 16, color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.bold),
                            ),
                            trailing: const Icon(Icons.edit_calendar, size: 20),
                            onTap: _pickStartDate,
                          ),
                          const SizedBox(height: 15),
                          DropdownButtonFormField<String>(
                            value: _repeatType,
                            decoration: InputDecoration(
                              labelText: 'repeat_type'.tr(),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.repeat, color: Colors.purple, size: 20),
                              ),
                              border: InputBorder.none,
                            ),
                            icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
                            items: _repeatTypes.map((t) {
                              String label;
                              switch (t) {
                                case 'NONE': label = 'repeat_none'.tr(); break;
                                case 'DAILY': label = 'repeat_daily'.tr(); break;
                                case 'WEEKLY': label = 'repeat_weekly'.tr(); break;
                                case 'MONTHLY': label = 'repeat_monthly'.tr(); break;
                                case 'YEARLY': label = 'repeat_yearly'.tr(); break;
                                case 'CUSTOM': label = 'repeat_custom'.tr(); break;
                                default: label = t;
                              }
                              return DropdownMenuItem(value: t, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _repeatType = v);
                            },
                          ),
                          if (_repeatType == 'CUSTOM') ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'selected_dates'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final tomorrow = DateTime(now.year, now.month, now.day + 1);
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: tomorrow,
                                      firstDate: tomorrow,
                                      lastDate: now.add(const Duration(days: 365 * 5)),
                                    );
                                    if (picked != null) {
                                      // Check if already exists
                                      final isDuplicate = _customDates.any((d) => 
                                        d.year == picked.year && d.month == picked.month && d.day == picked.day);
                                      if (isDuplicate) {
                                        ToastNotification.show(context, 'date_already_added'.tr(), status: ToastStatus.warning);
                                      } else {
                                        setState(() {
                                          _customDates.add(picked);
                                          _customDates.sort((a, b) => a.compareTo(b));
                                        });
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.edit_calendar),
                                  label: Text('add_date'.tr()),
                                ),
                              ],
                            ),
                            if (_customDates.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Text('no_dates_selected'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _customDates.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, idx) {
                                  final d = _customDates[idx];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.event, size: 20, color: Colors.blue),
                                        const SizedBox(width: 12),
                                        Text(
                                          DateFormat('dd/MM/yyyy').format(d),
                                          style: const TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _customDates.removeAt(idx);
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // BOTTOM SAVE ACTION
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'save'.tr(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
