// lib/src/features/transactions/transaction_screen.dart
import 'package:flutter/material.dart';
import 'transaction_model.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Danh sách các giao dịch (lưu tạm trong RAM)
  final List<Transaction> _transactions = [];

  // Controllers cho form
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // State cho dropdown và date picker
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  // Danh sách các danh mục
  final List<String> _categories = [
    'Ăn uống',
    'Xăng xe',
    'Mua sắm',
    'Giải trí',
    'Y tế',
    'Giáo dục',
    'Khác',
  ];

  // Hàm định dạng số tiền
  String formatCurrency(num amount) {
    return "${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ";
  }

  // Hàm định dạng ngày
  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // Hàm chọn ngày
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

  // Hàm validate và lưu giao dịch
  void _saveTransaction() {
    // Kiểm tra form có hợp lệ không
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate: Kiểm tra tiền có < 0 không
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền phải lớn hơn 0!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate: Kiểm tra đã chọn danh mục chưa
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tạo giao dịch mới và thêm vào danh sách
    final newTransaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      note: _noteController.text.trim(),
      category: _selectedCategory!,
      date: _selectedDate,
    );

    setState(() {
      _transactions.add(newTransaction);
      // Sắp xếp theo ngày mới nhất trước
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    });

    // Reset form
    _amountController.clear();
    _noteController.clear();
    _selectedCategory = null;

    // Hiển thị thông báo thành công
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu giao dịch thành công!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Hàm xóa giao dịch
  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((transaction) => transaction.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa giao dịch!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề
                Text(
                  'Thêm Giao dịch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Form nhập liệu
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // TextField nhập tiền
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'Số tiền',
                            hintText: 'Nhập số tiền',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Vui lòng nhập số tiền';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null) {
                              return 'Số tiền không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // TextField nhập ghi chú
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú',
                            hintText: 'Nhập ghi chú (tùy chọn)',
                            prefixIcon: Icon(Icons.note),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),

                        // DropdownButton chọn danh mục
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
                          onChanged: (String? newValue) {
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

                        // DatePicker chọn ngày
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
                                Text(formatDate(_selectedDate)),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Nút Lưu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveTransaction,
                            icon: const Icon(Icons.save),
                            label: const Text('Lưu'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Danh sách giao dịch
                Text(
                  'Danh sách Giao dịch',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),

                // ListView.builder để hiển thị danh sách
                _transactions.isEmpty
                    ? Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inbox,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Chưa có giao dịch nào',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal,
                                child: Icon(
                                  _getCategoryIcon(transaction.category),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                transaction.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (transaction.note.isNotEmpty)
                                    Text(transaction.note),
                                  Text(
                                    formatDate(transaction.date),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formatCurrency(transaction.amount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // IconButton xóa
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () =>
                                        _deleteTransaction(transaction.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hàm lấy icon theo danh mục
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant;
      case 'Xăng xe':
        return Icons.local_gas_station;
      case 'Mua sắm':
        return Icons.shopping_cart;
      case 'Giải trí':
        return Icons.movie;
      case 'Y tế':
        return Icons.medical_services;
      case 'Giáo dục':
        return Icons.school;
      default:
        return Icons.category;
    }
  }
}
