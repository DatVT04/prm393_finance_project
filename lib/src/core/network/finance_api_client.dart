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

  static int? _userId;
  static void setUserId(int? id) {
    _userId = id;
  }

  String _errorMessage(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map) {
        if (data.containsKey('message') && data['message'] != null) {
          return data['message'].toString();
        }
        if (data.containsKey('error') && data['error'] != null) {
          return data['error'].toString();
        }
      }
    } catch (_) {}
    return body.isNotEmpty ? body : 'Đã có lỗi xảy ra';
  }

  String get _base => ApiConstants.baseUrl;

  /// Headers for requests that are scoped by user (accounts, entries).
  Map<String, String> get _userHeaders => {
    'Content-Type': 'application/json',
    if (_userId != null) 'X-User-Id': _userId.toString(),
  };

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

  Future<Map<String, dynamic>> googleLogin(String email, String? displayName) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/google-login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'displayName': displayName,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res.body));
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.authPath}/password'),
      headers: _userHeaders,
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(res.body.isNotEmpty ? res.body : 'Đổi mật khẩu thất bại: ${res.statusCode}');
    }
  }

  Future<String> uploadAvatar(List<int> bytes, String filename) async {
    final uri = Uri.parse('$_base${ApiConstants.authPath}/avatar');
    final req = http.MultipartRequest('POST', uri);
    if (_userId != null) req.headers['X-User-Id'] = _userId.toString();
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final res = await req.send();
    final resData = await http.Response.fromStream(res);
    if (res.statusCode != 200) {
      throw Exception(resData.body.isNotEmpty ? resData.body : 'Upload avatar thất bại: ${res.statusCode}');
    }
    return resData.body;
  }

  Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/forgot-password?email=$email'),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res.body));
    }
  }

  Future<void> resetPassword(String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception(_errorMessage(res.body));
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        if (displayName != null && displayName.isNotEmpty)
          'displayName': displayName,
      }),
    );
    if (res.statusCode == 409) {
      throw Exception('Email này đã được đăng ký');
    }
    if (res.statusCode != 201 && res.statusCode != 200) {
      final body = res.body;
      throw Exception(
        body.isNotEmpty ? body : 'Đăng ký thất bại: ${res.statusCode}',
      );
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<CategoryModel>> getCategories() async {
    final res = await http.get(
      Uri.parse('$_base${ApiConstants.categoriesPath}'),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to load categories: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.categoriesPath}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toCreateJson()),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty
            ? res.body
            : 'Failed to create category: ${res.statusCode}',
      );
    }
    return CategoryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<CategoryModel> updateCategory(int id, CategoryModel category) async {
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.categoriesPath}/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(category.toCreateJson()),
    );
    if (res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty
            ? res.body
            : 'Failed to update category: ${res.statusCode}',
      );
    }
    return CategoryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('$_base${ApiConstants.categoriesPath}/$id'),
    );
    if (res.statusCode != 204)
      throw Exception('Failed to delete category: ${res.statusCode}');
  }

  Future<List<AccountModel>> getAccounts() async {
    final res = await http.get(
      Uri.parse('$_base${ApiConstants.accountsPath}'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200)
      throw Exception('Failed to load accounts: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AccountModel> createAccount(String name, double balance) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.accountsPath}'),
      headers: _userHeaders,
      body: jsonEncode({'name': name, 'balance': balance}),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty
            ? res.body
            : 'Failed to create account: ${res.statusCode}',
      );
    }
    return AccountModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<AccountModel> updateAccount(
    int id,
    String name,
    double balance,
  ) async {
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.accountsPath}/$id'),
      headers: _userHeaders,
      body: jsonEncode({'name': name, 'balance': balance}),
    );
    if (res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty
            ? res.body
            : 'Failed to update account: ${res.statusCode}',
      );
    }
    return AccountModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteAccount(int id) async {
    final res = await http.delete(
      Uri.parse('$_base${ApiConstants.accountsPath}/$id'),
      headers: _userHeaders,
    );
    if (res.statusCode == 409 && res.body.isNotEmpty) {
      throw Exception(res.body);
    }
    if (res.statusCode != 204)
      throw Exception('Không thể xóa ví: ${res.statusCode}');
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

    final res = await http.get(uri, headers: _userHeaders);
    if (res.statusCode != 200)
      throw Exception('Failed to load entries: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => FinancialEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FinancialEntryModel> createEntry(FinancialEntryModel entry) async {
    final body = entry.toCreateJson();
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.entriesPath}'),
      headers: _userHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty
            ? res.body
            : 'Failed to create entry: ${res.statusCode}',
      );
    }
    return FinancialEntryModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<FinancialEntryModel> updateEntry(
    int id,
    FinancialEntryModel entry,
  ) async {
    final body = entry.toCreateJson();
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.entriesPath}/$id'),
      headers: _userHeaders,
      body: jsonEncode(body),
    );
    if (res.statusCode != 200) {
      throw Exception(
        res.body.isNotEmpty
            ? res.body
            : 'Failed to update entry: ${res.statusCode}',
      );
    }
    return FinancialEntryModel.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<void> uploadImage(int id, String filePath) async {
    final uri = Uri.parse('$_base${ApiConstants.entriesPath}/$id/image');
    final req = http.MultipartRequest('POST', uri);
    if (_userId != null) req.headers['X-User-Id'] = _userId.toString();
    req.files.add(await http.MultipartFile.fromPath('file', filePath));
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Failed to upload image: ${res.statusCode}');
  }

  Future<void> uploadImageBytes(
    int id,
    List<int> bytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_base${ApiConstants.entriesPath}/$id/image');
    final req = http.MultipartRequest('POST', uri);
    if (_userId != null) req.headers['X-User-Id'] = _userId.toString();
    req.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final res = await req.send();
    if (res.statusCode != 200)
      throw Exception('Failed to upload image bytes: ${res.statusCode}');
  }

  Future<void> deleteEntry(int id) async {
    final res = await http.delete(
      Uri.parse('$_base${ApiConstants.entriesPath}/$id'),
      headers: _userHeaders,
    );
    if (res.statusCode != 204)
      throw Exception('Failed to delete entry: ${res.statusCode}');
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
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
        if (accountId != null) 'accountId': accountId,
      }),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to ask AI: ${res.statusCode}');
    return AiAssistantResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
