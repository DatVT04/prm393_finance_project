class AccountModel {
  final int id;
  final String name;
  final double balance;
  final String? iconName;
  final String? colorHex;

  AccountModel({
    required this.id,
    required this.name,
    required this.balance,
    this.iconName,
    this.colorHex,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as int,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'balance': balance,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }
}
