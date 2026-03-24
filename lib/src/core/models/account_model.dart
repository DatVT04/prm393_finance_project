class AccountModel {
  final int id;
  final String name;
  final double balance;
  final String? iconName;
  final String? colorHex;
  final bool isDeleted;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.iconName,
    this.colorHex,
    this.isDeleted = false,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'iconName': iconName,
      'colorHex': colorHex,
      'isDeleted': isDeleted,
    };
  }
}
