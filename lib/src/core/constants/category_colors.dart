import 'package:flutter/material.dart';

class CategoryColors {
  static const _map = {
    'Ăn uống': Color(0xFF0293ee),
    'Xăng xe': Color(0xFF2196F3),
    'Mua sắm': Color(0xFFf8b250),
    'Giải trí': Color(0xFF845bef),
    'Y tế': Color(0xFFe94560),
    'Giáo dục': Color(0xFF3F51B5),
    'Gửi xe': Color(0xFF795548),
    'Nạp tiền': Color(0xFF4CAF50),
    'Khác': Color(0xFF13d38e),
  };

  static Color get(String categoryName) {
    return _map[categoryName] ?? const Color(0xFF13d38e);
  }
}
