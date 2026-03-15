import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/account_model.dart';
import '../models/ai_assistant_response.dart';
import '../models/category_model.dart';
import '../models/financial_entry_model.dart';

class FinanceApiClient {
  static final FinanceApiClient _instance = FinanceApiClient._();
  factory FinanceApiClient() => _instance;

  FinanceApiClient._();

  String get _base => ApiConstants.baseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (res.statusCode == 401) {
      throw Exception('Email hoặc mật khẩu không đúng');
    }
    if (res.statusCode != 200) {
      throw Exception('Đăng nhập thất bại: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<CategoryModel>> getCategories() async {
    final res = await http.get(Uri.parse('$_base${ApiConstants.categoriesPath}'));
    if (res.statusCode != 200) throw Exception('Failed to load categories: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.categoriesPath}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toCreateJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create category: ${res.statusCode}');
    }
    return CategoryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory(int id, CategoryModel category) async {
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.categoriesPath}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toCreateJson()),
    );
    if (res.statusCode != 200) throw Exception('Failed to update category: ${res.statusCode}');
    return CategoryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    final res = await http.delete(Uri.parse('$_base${ApiConstants.categoriesPath}/$id'));
    if (res.statusCode != 204) throw Exception('Failed to delete category: ${res.statusCode}');
  }

  Future<List<AccountModel>> getAccounts() async {
    final res = await http.get(Uri.parse('$_base${ApiConstants.accountsPath}'));
    if (res.statusCode != 200) throw Exception('Failed to load accounts: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => AccountModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AccountModel> createAccount(String name, double balance) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.accountsPath}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'balance': balance}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to create account: ${res.statusCode}');
    }
    return AccountModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
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
    if (res.statusCode != 201 && res.statusCode != 200) throw Exception('Failed to create entry: ${res.statusCode}');
    return FinancialEntryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<FinancialEntryModel> updateEntry(int id, FinancialEntryModel entry) async {
    final body = entry.toCreateJson();
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.entriesPath}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) throw Exception('Failed to update entry: ${res.statusCode}');
    return FinancialEntryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> uploadImage(int id, String filePath) async {
    final uri = Uri.parse('$_base${ApiConstants.entriesPath}/$id/image');
    final req = http.MultipartRequest('POST', uri);
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await req.send();
    if (res.statusCode != 200) throw Exception('Failed to upload image: ${res.statusCode}');
  }

  Future<void> deleteEntry(int id) async {
    final res = await http.delete(Uri.parse('$_base${ApiConstants.entriesPath}/$id'));
    if (res.statusCode != 204) throw Exception('Failed to delete entry: ${res.statusCode}');
  }

  Future<AiAssistantResponse> askAssistant(
    String message, {
    String? conversationId,
    int? accountId,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/ai/assistant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty) 'conversationId': conversationId,
        if (accountId != null) 'accountId': accountId,
      }),
    );
    if (res.statusCode != 200) throw Exception('Failed to ask AI: ${res.statusCode}');
    return AiAssistantResponse.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
