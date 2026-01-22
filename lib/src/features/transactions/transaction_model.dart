// lib/src/features/transactions/transaction_model.dart
class Transaction {
  final String id;
  final double amount;
  final String note;
  final String category;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.note,
    required this.category,
    required this.date,
  });
}
