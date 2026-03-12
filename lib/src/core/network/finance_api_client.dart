import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/category_model.dart';
import '../models/financial_entry_model.dart';

class FinanceApiClient {
  static final FinanceApiClient _instance = FinanceApiClient._();
  factory FinanceApiClient() => _instance;

  FinanceApiClient._();

  String get _base => ApiConstants.baseUrl;

  Future<List<CategoryModel>> getCategories() async {
    final res = await http.get(Uri.parse('$_base${ApiConstants.categoriesPath}'));
    if (res.statusCode != 200) throw Exception('Failed to load categories: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<FinancialEntryModel>> getEntries({
    DateTime? from,
    DateTime? to,
    String? tag,
  }) async {
    var uri = Uri.parse('$_base${ApiConstants.entriesPath}');
    final q = <String, String>{};
    if (from != null) q['from'] = _dateStr(from);
    if (to != null) q['to'] = _dateStr(to);
    if (tag != null && tag.isNotEmpty) q['tag'] = tag;
    if (q.isNotEmpty) uri = uri.replace(queryParameters: q);

    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load entries: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => FinancialEntryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<FinancialEntryModel> createEntry(FinancialEntryModel entry) async {
    final body = entry.toCreateJson();
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.entriesPath}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 201) throw Exception('Failed to create entry: ${res.statusCode}');
    return FinancialEntryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteEntry(int id) async {
    final res = await http.delete(Uri.parse('$_base${ApiConstants.entriesPath}/$id'));
    if (res.statusCode != 204) throw Exception('Failed to delete entry: ${res.statusCode}');
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
