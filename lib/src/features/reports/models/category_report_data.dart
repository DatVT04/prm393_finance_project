import 'package:easy_localization/easy_localization.dart';

class CategoryReportData {
  final String name;
  final double totalAmount;
  final String? iconName;
  final String? colorHex;

  CategoryReportData({
    required this.name,
    required this.totalAmount,
    this.iconName,
    this.colorHex,
  });

  String get displayName => (name.toLowerCase() == 'khác' || name.toLowerCase() == 'other') ? 'other' : name;
}
