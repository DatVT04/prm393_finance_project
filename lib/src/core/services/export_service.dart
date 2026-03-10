import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
      TextCellValue('Tags'),
      TextCellValue('Nguồn'),
    ]);
    for (final e in entries) {
      sheet.appendRow([
        TextCellValue(_dateFormat.format(e.transactionDate)),
        TextCellValue(e.categoryName ?? ''),
        IntCellValue(e.amount.toInt()),
        TextCellValue(e.note ?? ''),
        TextCellValue(e.tags.join(', ')),
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

  /// Export entries to PDF and share.
  static Future<String> exportToPdf(List<FinancialEntryModel> entries, {Rect? sharePositionOrigin}) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Nhật ký Tài chính Thông minh',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: pw.TableBorder.all(width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _cell('Ngày'),
                  _cell('Danh mục'),
                  _cell('Số tiền'),
                  _cell('Ghi chú'),
                ],
              ),
              ...entries.map((e) => pw.TableRow(
                    children: [
                      _cell(_dateFormat.format(e.transactionDate)),
                      _cell(e.categoryName ?? ''),
                      _cell('${_numberFormat.format(e.amount)} đ'),
                      _cell((e.note ?? '').length > 40 ? '${(e.note ?? '').substring(0, 40)}...' : (e.note ?? '')),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );

    final name = 'Nhat_ky_tai_chinh_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
    final bytes = await pdf.save();

    if (kIsWeb) {
      final xFile = XFile.fromData(bytes, name: name, mimeType: 'application/pdf');
      await Share.shareXFiles([xFile], text: 'Xuất nhật ký tài chính (PDF)', sharePositionOrigin: sharePositionOrigin);
      return '';
    }

    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$name';
    final file = File(path);
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(path)], text: 'Xuất nhật ký tài chính (PDF)', sharePositionOrigin: sharePositionOrigin);
    return path;
  }

  static pw.Widget _cell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
}
