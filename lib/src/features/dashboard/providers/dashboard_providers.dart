import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thu nhập của tháng hiện tại (người dùng tự nhập ở màn Tổng quan).
final monthlyIncomeProvider = StateProvider<double>((ref) => 0);

