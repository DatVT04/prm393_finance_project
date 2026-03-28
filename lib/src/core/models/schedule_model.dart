import 'dart:convert';

class ScheduleModel {
  final int? id;
  final int accountId;
  final int categoryId;
  final int? userId;
  final double amount;
  final String? note;
  final DateTime startDate;
  final String repeatType;
  final String? repeatConfig;
  final DateTime? nextRun;
  final String? type; // INCOME, EXPENSE
  final bool isActive;

  ScheduleModel({
    this.id,
    required this.accountId,
    required this.categoryId,
    this.userId,
    required this.amount,
    this.note,
    required this.startDate,
    required this.repeatType,
    this.repeatConfig,
    this.nextRun,
    this.type,
    this.isActive = true,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'],
      accountId: json['accountId'],
      categoryId: json['categoryId'],
      userId: json['userId'],
      amount: (json['amount'] as num).toDouble(),
      note: json['note'],
      startDate: DateTime.parse(json['startDate']),
      repeatType: json['repeatType'] ?? 'NONE',
      repeatConfig: json['repeatConfig'],
      nextRun: json['nextRun'] != null ? DateTime.parse(json['nextRun']) : null,
      type: json['type'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'categoryId': categoryId,
      if (userId != null) 'userId': userId,
      'amount': amount,
      'note': note,
      'startDate': startDate.toIso8601String(),
      'repeatType': repeatType,
      if (repeatConfig != null) 'repeatConfig': repeatConfig,
      if (nextRun != null) 'nextRun': nextRun!.toIso8601String(),
      if (type != null) 'type': type,
      'isActive': isActive,
    };
  }

  ScheduleModel copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    int? userId,
    double? amount,
    String? note,
    DateTime? startDate,
    String? repeatType,
    String? repeatConfig,
    DateTime? nextRun,
    String? type,
    bool? isActive,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      startDate: startDate ?? this.startDate,
      repeatType: repeatType ?? this.repeatType,
      repeatConfig: repeatConfig ?? this.repeatConfig,
      nextRun: nextRun ?? this.nextRun,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
    );
  }
}
