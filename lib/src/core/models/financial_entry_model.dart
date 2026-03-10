class FinancialEntryModel {
  final int id;
  final double amount;
  final String? note;
  final int categoryId;
  final String? categoryName;
  final DateTime transactionDate;
  final List<String> tags;
  final List<String> mentions;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final String type; // INCOME, EXPENSE, TRANSFER
  final int accountId;
  final int? toAccountId;
  final String? source;
  final DateTime? createdAt;

  FinancialEntryModel({
    required this.id,
    required this.amount,
    this.note,
    required this.categoryId,
    this.categoryName,
    required this.transactionDate,
    this.tags = const [],
    this.mentions = const [],
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.source,
    this.createdAt,
  });

  factory FinancialEntryModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    final mentionsRaw = json['mentions'];
    return FinancialEntryModel(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      note: json['note'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
      tags: tagsRaw is List ? (tagsRaw).map((e) => e.toString()).toList() : [],
      mentions: mentionsRaw is List ? (mentionsRaw).map((e) => e.toString()).toList() : [],
      imageUrl: json['imageUrl'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      type: json['type'] as String? ?? 'EXPENSE',
      accountId: json['accountId'] as int? ?? 1,
      toAccountId: json['toAccountId'] as int?,
      source: json['source'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
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
      if (toAccountId != null) 'toAccountId': toAccountId,
      if (tags.isNotEmpty) 'tags': tags,
      if (mentions.isNotEmpty) 'mentions': mentions,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (source != null && source!.isNotEmpty) 'source': source,
    };
  }
}
