class CategoryModel {
  final int id;
  final String name;
  final String? type; // INCOME, EXPENSE, TRANSFER
  final String? iconName;
  final String? colorHex;
  final bool isFixed;

  CategoryModel({
    required this.id,
    required this.name,
    this.type,
    this.iconName,
    this.colorHex,
    this.isFixed = false,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      isFixed: json['fixed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      if (type != null) 'type': type,
      if (iconName != null && iconName!.isNotEmpty) 'iconName': iconName,
      if (colorHex != null && colorHex!.isNotEmpty) 'colorHex': colorHex,
    };
  }

  String get displayName {
    if (name.toLowerCase() == 'khác' || name.toLowerCase() == 'other') {
      return 'other'; // Returns the translation key
    }
    return name;
  }
}
