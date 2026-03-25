import 'package:flutter/material.dart';

class CategoryColors {
  static const _map = {
    'Khác': Color(0xFF13d38e),
  };

  static Color get(String categoryName) {
    return _map[categoryName] ?? const Color(0xFF13d38e);
  }
}
