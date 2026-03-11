class CategoryModel {
  final int id;
  final String name;
  final String? iconName;
  final String? colorHex;
  final int? sortOrder;

  CategoryModel({
    required this.id,
    required this.name,
    this.iconName,
    this.colorHex,
    this.sortOrder,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      iconName: json['iconName'] as String?,
      colorHex: json['colorHex'] as String?,
      sortOrder: json['sortOrder'] as int?,
    );
  }
}
