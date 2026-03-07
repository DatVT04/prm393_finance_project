import 'package:intl/intl.dart';

class BudgetModel {
  final int? id;
  final int? userId;
  final int categoryId;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;

  BudgetModel({
    this.id,
    this.userId,
    required this.categoryId,
    required this.amount,
    required this.startDate,
    required this.endDate,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel(
      id: json['id'],
      userId: json['userId'],
      categoryId: json['categoryId'],
      amount: (json['amount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
    );
  }

  Map<String, dynamic> toJson() {
    final fmt = DateFormat('yyyy-MM-dd');
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'categoryId': categoryId,
      'amount': amount,
      'startDate': fmt.format(startDate),
      'endDate': fmt.format(endDate),
    };
  }

  BudgetModel copyWith({
    int? id,
    int? userId,
    int? categoryId,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
