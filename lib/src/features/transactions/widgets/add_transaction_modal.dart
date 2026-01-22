import 'package:flutter/material.dart';
import '../transaction_model.dart';
import 'package:intl/intl.dart';

class AddTransactionModal extends StatefulWidget {
  const AddTransactionModal({super.key});

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Ăn uống',
    'Xăng xe',
    'Mua sắm',
    'Giải trí',
    'Y tế',
    'Giáo dục',
    'Khác',
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitData() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final enteredAmount = double.parse(_amountController.text);

    // Safety check just in case
    if (_selectedCategory == null) return;

    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: enteredAmount,
      note: _noteController.text,
      category: _selectedCategory!,
      date: _selectedDate,
    );

    Navigator.of(context).pop(newTransaction);
  }

  @override
  Widget build(BuildContext context) {
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
                'Thêm Giao dịch Mới',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Amount Input
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                  helperText: 'Ví dụ: 50.000',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  // Remove non-digits (commas, dots if used as separators) to check pure number
                  // For simplicity, just try parsing.
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Số tiền không hợp lệ (chỉ nhập số)';
                  }
                  if (amount <= 0) {
                    return 'Số tiền phải lớn hơn 0';
                  }
                  if (amount > 10000000000) {
                    // 10 billion limt
                    return 'Số tiền quá lớn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng chọn danh mục';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Note Input
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (Tùy chọn)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true, // Align label to top for textarea
                ),
                maxLines: 3, // Make it a textarea
                maxLength: 250, // Increase limit
              ),
              const SizedBox(height: 16),
              // Date Picker
              InkWell(
                onTap: () => _selectDate(context),
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
              const SizedBox(height: 32),
              // Submit Button
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lưu Giao dịch',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
