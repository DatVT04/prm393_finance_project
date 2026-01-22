import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'transaction_model.dart';
import 'widgets/add_transaction_modal.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  // Mock data
  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      amount: 50000,
      note: 'Phở bò',
      category: 'Ăn uống',
      date: DateTime.now(),
    ),
    Transaction(
      id: '2',
      amount: 1500000,
      note: 'Đổ xăng tháng này',
      category: 'Xăng xe',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  void _openAddTransactionModal(BuildContext context) async {
    final newTransaction = await showModalBottomSheet<Transaction>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return const AddTransactionModal();
      },
    );

    if (newTransaction != null) {
      setState(() {
        _transactions.add(newTransaction);
        _transactions.sort((a, b) => b.date.compareTo(a.date));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã thêm giao dịch mới'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã xóa giao dịch'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Map<String, List<Transaction>> _groupTransactionsByDate() {
    Map<String, List<Transaction>> grouped = {};
    for (var tx in _transactions) {
      String dateKey = DateFormat('dd/MM/yyyy').format(tx.date);
      if (grouped.containsKey(dateKey)) {
        grouped[dateKey]!.add(tx);
      } else {
        grouped[dateKey] = [tx];
      }
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactionsByDate();
    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) {
        // Simple sort assuming date format dd/MM/yyyy
        // Ideally should convert back to DateTime for sort
        DateTime dateA = DateFormat('dd/MM/yyyy').parse(a);
        DateTime dateB = DateFormat('dd/MM/yyyy').parse(b);
        return dateB.compareTo(dateA);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giao dịch',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {}, // Filter feature for later
            icon: const Icon(Icons.filter_list),
            color: Colors.black87,
          ),
        ],
      ),
      body: _transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Colors.teal.shade200,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa có giao dịch nào',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cham vào nút (+) để thêm giao dịch mới',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8),
              itemCount: sortedKeys.length,
              itemBuilder: (context, index) {
                final dateStr = sortedKeys[index];
                final transactions = groupedTransactions[dateStr]!;

                // Calculate daily total
                final dailyTotal = transactions.fold(
                  0.0,
                  (sum, item) => sum + item.amount,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDateHeader(dateStr),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '-${NumberFormat("#,###", "vi_VN").format(dailyTotal)} đ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        final tx = transactions[i];
                        return _buildTransactionItem(tx);
                      },
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransactionModal(context),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDateHeader(String dateStr) {
    if (dateStr == DateFormat('dd/MM/yyyy').format(DateTime.now())) {
      return 'Hôm nay';
    } else if (dateStr ==
        DateFormat(
          'dd/MM/yyyy',
        ).format(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Hôm qua';
    }
    return dateStr;
  }

  Widget _buildTransactionItem(Transaction tx) {
    return Dismissible(
      key: Key(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade100,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) => _deleteTransaction(tx.id),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(tx.category).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(tx.category),
              color: _getCategoryColor(tx.category),
              size: 20,
            ),
          ),
          title: Text(
            tx.category,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          subtitle: tx.note.isNotEmpty
              ? Text(
                  tx.note,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Text(
            '-${NumberFormat("#,###", "vi_VN").format(tx.amount)} đ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Ăn uống':
        return Icons.restaurant;
      case 'Xăng xe':
        return Icons.local_gas_station;
      case 'Mua sắm':
        return Icons.shopping_bag;
      case 'Giải trí':
        return Icons.confirmation_number;
      case 'Y tế':
        return Icons.medical_services;
      case 'Giáo dục':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Ăn uống':
        return Colors.orange;
      case 'Xăng xe':
        return Colors.blue;
      case 'Mua sắm':
        return Colors.purple;
      case 'Giải trí':
        return Colors.pink;
      case 'Y tế':
        return Colors.red;
      case 'Giáo dục':
        return Colors.indigo;
      default:
        return Colors.teal;
    }
  }
}
