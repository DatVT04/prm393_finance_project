class FinancialEntryModel {
  final int id;
  final double amount;
  final String? note;
  final int categoryId;
  final String? categoryName;
  final DateTime transactionDate;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String type; // INCOME, EXPENSE
  final int accountId;
  final String? source;
  final DateTime? createdAt;

  // Styling fields from backend
  final String? categoryIconName;
  final String? categoryColorHex;
  final String? accountIconName;
  final String? accountColorHex;

  FinancialEntryModel({
    required this.id,
    required this.amount,
    this.note,
    required this.categoryId,
    this.categoryName,
    required this.transactionDate,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.type,
    required this.accountId,
    this.source,
    this.createdAt,
    this.categoryIconName,
    this.categoryColorHex,
    this.accountIconName,
    this.accountColorHex,
  });

  factory FinancialEntryModel.fromJson(Map<String, dynamic> json) {
    return FinancialEntryModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      imageUrl: json['imageUrl'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      type: json['type'] as String? ?? 'EXPENSE',
      accountId: json['accountId'] as int? ?? 1,
      source: json['source'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      categoryIconName: json['categoryIconName'] as String?,
      categoryColorHex: json['categoryColorHex'] as String?,
      accountIconName: json['accountIconName'] as String?,
      accountColorHex: json['accountColorHex'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'amount': amount,
      'note': note,
      'categoryId': categoryId,
      'accountId': accountId,
      'type': type,
      'transactionDate': transactionDate.toIso8601String().split('T').first,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (source != null && source!.isNotEmpty) 'source': source,
    };
  }
}
