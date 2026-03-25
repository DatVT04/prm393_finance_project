import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/financial_entry_model.dart';

class ExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _numberFormat = NumberFormat('#,###', 'vi_VN');

  /// Export entries to Excel and return file path. Share via share_plus.
  static Future<String> exportToExcel(List<FinancialEntryModel> entries, {Rect? sharePositionOrigin}) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    sheet.appendRow([
      TextCellValue('Ngày'),
      TextCellValue('Danh mục'),
      TextCellValue('Số tiền'),
      TextCellValue('Ghi chú'),
      TextCellValue('Nguồn'),
    ]);
    for (final e in entries) {
      sheet.appendRow([
        TextCellValue(_dateFormat.format(e.transactionDate)),
        TextCellValue(e.categoryName ?? ''),
        IntCellValue(e.amount.toInt()),
        TextCellValue(e.note ?? ''),
        TextCellValue(e.source ?? ''),
      ]);
    }

    final name = 'Nhat_ky_tai_chinh_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.xlsx';
    final bytes = excel.encode();
    if (bytes == null) return '';

    if (kIsWeb) {
      final xFile = XFile.fromData(Uint8List.fromList(bytes), name: name, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      await Share.shareXFiles([xFile], text: 'Xuất nhật ký tài chính (Excel)', sharePositionOrigin: sharePositionOrigin);
      return '';
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$name';
    final file = File(path);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)], text: 'Xuất nhật ký tài chính (Excel)', sharePositionOrigin: sharePositionOrigin);
    return path;
  }

}
