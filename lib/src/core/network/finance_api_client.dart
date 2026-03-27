import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/account_model.dart';
import '../models/ai_assistant_response.dart';
import '../models/category_model.dart';
import '../models/financial_entry_model.dart';
import '../models/budget_model.dart';
import '../models/schedule_model.dart';
import '../error/app_exception.dart';

class FinanceApiClient {
  static final FinanceApiClient _instance = FinanceApiClient._();
  factory FinanceApiClient() => _instance;

  FinanceApiClient._();

  static int? _userId;
  static String _language = 'vi';

  static void setUserId(int? id) {
    _userId = id;
  }

  static void setLanguage(String lang) {
    _language = lang;
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
    'Accept-Language': _language,
    if (_userId != null) 'X-User-Id': _userId.toString(),
  };

  /**
   * Đăng nhập người dùng bằng email và mật khẩu. Trả về thông tin người dùng và token.
   */
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (res.statusCode == 401) {
      throw AppException('Email hoặc mật khẩu không đúng');
    }
    if (res.statusCode == 403) {
      final body = jsonDecode(res.body);
      throw AppException(body['message'] ?? 'Tài khoản chưa được kích hoạt');
    }
    if (res.statusCode != 200) {
      throw AppException('Đăng nhập thất bại: ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /**
   * Xác thực tài khoản qua mã code gửi về email.
   */
  Future<void> verifyAccount(String email, String code) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/verify-account?email=$email&code=$code'),
    );
    if (res.statusCode != 200) {
      throw AppException(_errorMessage(res.body));
    }
  }

  /**
   * Gửi lại mã xác thực tới email người dùng.
   */
  Future<void> resendVerificationCode(String email) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.authPath}/resend-verification-code?email=$email'),
    );
    if (res.statusCode != 200) {
      throw AppException(_errorMessage(res.body));
    }
  }

  /**
   * Đăng nhập hoặc đăng ký nhanh bằng Google Account.
   */
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
      throw AppException(_errorMessage(res.body));
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
      throw AppException(res.body.isNotEmpty ? res.body : 'Đổi mật khẩu thất bại: ${res.statusCode}');
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.authPath}/display-name'),
      headers: _userHeaders,
      body: jsonEncode({
        'displayName': displayName.trim(),
      }),
    );
    if (res.statusCode != 200) {
      throw AppException(_errorMessage(res.body));
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
      throw AppException(_errorMessage(res.body));
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
      throw AppException(_errorMessage(res.body));
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
      Uri.parse('$_base${ApiConstants.categoriesPath}?t=${DateTime.now().millisecondsSinceEpoch}'),
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
      throw AppException(_errorMessage(res.body));
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
      throw AppException(_errorMessage(res.body));
    }
    return CategoryModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('$_base${ApiConstants.categoriesPath}/$id'),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw AppException(_errorMessage(res.body));
    }
  }

  Future<List<AccountModel>> getAccounts({bool includeDeleted = false}) async {
    final uri = Uri.parse('$_base${ApiConstants.accountsPath}')
        .replace(queryParameters: {'includeDeleted': includeDeleted.toString()});
    final res = await http.get(
      uri,
      headers: _userHeaders,
    );
    if (res.statusCode != 200)
      throw Exception('Failed to load accounts: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list
        .map((e) => AccountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AccountModel> createAccount(
    String name,
    double balance, {
    String? iconName,
    String? colorHex,
  }) async {
    final res = await http.post(
      Uri.parse('$_base${ApiConstants.accountsPath}'),
      headers: _userHeaders,
      body: jsonEncode({
        'name': name,
        'balance': balance,
        if (iconName != null) 'iconName': iconName,
        if (colorHex != null) 'colorHex': colorHex,
      }),
    );
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw AppException(_errorMessage(res.body));
    }
    return AccountModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
 
  Future<AccountModel> updateAccount(
    int id,
    String name,
    double balance, {
    String? iconName,
    String? colorHex,
  }) async {
    final res = await http.put(
      Uri.parse('$_base${ApiConstants.accountsPath}/$id'),
      headers: _userHeaders,
      body: jsonEncode({
        'name': name,
        'balance': balance,
        if (iconName != null) 'iconName': iconName,
        if (colorHex != null) 'colorHex': colorHex,
      }),
    );
    if (res.statusCode != 200) {
      throw AppException(_errorMessage(res.body));
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
  }) async {
    var uri = Uri.parse('$_base${ApiConstants.entriesPath}');
    final q = <String, String>{};
    q['t'] = DateTime.now().millisecondsSinceEpoch.toString();
    if (from != null) q['from'] = _dateStr(from);
    if (to != null) q['to'] = _dateStr(to);
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

  /**
   * Phương thức chính để gửi câu hỏi/yêu cầu tới Trợ lý AI.
   * Chấp nhận tin nhắn văn bản, ID hội thoại, ID ví, ngôn ngữ và ảnh base64.
   */
  Future<AiAssistantResponse> askAssistant(
    String message, {
    String? conversationId,
    int? accountId,
    String? language,
    String? base64Image,
  }) async {
    final res = await http.post(
      Uri.parse('$_base/api/ai/assistant'),
      headers: _userHeaders,
      body: jsonEncode({
        'message': message,
        if (conversationId != null && conversationId.isNotEmpty)
          'conversationId': conversationId,
        if (accountId != null) 'accountId': accountId,
        if (language != null && language.isNotEmpty) 'language': language,
        if (base64Image != null && base64Image.isNotEmpty) 'base64Image': base64Image,
      }),
    );
    if (res.statusCode != 200)
      throw Exception('Failed to ask AI: ${res.statusCode}');
    return AiAssistantResponse.fromJson(
      jsonDecode(res.body) as Map<String, dynamic>,
    );
  }

  Future<List<BudgetModel>> getBudgets() async {
    final res = await http.get(
      Uri.parse('$_base/api/budgets'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) throw Exception('Failed to load budgets');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => BudgetModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /**
   * Lấy lịch sử tất cả các tin nhắn chat của AI Assistant từ server.
   */
  Future<List<Map<String, dynamic>>> getAiHistory() async {
    final res = await http.get(
      Uri.parse('$_base/api/ai/history'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) throw Exception('Failed to load AI history');
    final list = jsonDecode(res.body) as List;
    return list.cast<Map<String, dynamic>>();
  }

  /**
   * Xóa sạch lịch sử chat của AI trên server.
   */
  Future<void> clearAiHistory() async {
    final res = await http.delete(
      Uri.parse('$_base/api/ai/history'),
      headers: _userHeaders,
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw Exception('Failed to clear AI history: ${res.statusCode}');
    }
  }

  Future<BudgetModel> upsertBudget(BudgetModel budget) async {
    final res = await http.post(
      Uri.parse('$_base/api/budgets'),
      headers: _userHeaders,
      body: jsonEncode(budget.toJson()),
    );
    if (res.statusCode != 200) throw Exception('Failed to save budget');
    return BudgetModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> deleteBudget(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/api/budgets/$id'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) throw Exception('Failed to delete budget');
  }

  Future<List<ScheduleModel>> getSchedules() async {
    if (_userId == null) throw Exception('User not logged in');
    final res = await http.get(
      Uri.parse('$_base/api/schedules/user/$_userId'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) throw Exception('Failed to load schedules: ${res.statusCode}');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => ScheduleModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ScheduleModel> createSchedule(ScheduleModel schedule) async {
    final s = schedule.copyWith(userId: _userId);
    final res = await http.post(
      Uri.parse('$_base/api/schedules'),
      headers: _userHeaders,
      body: jsonEncode(s.toJson()),
    );
    if (res.statusCode != 200 && res.statusCode != 201) throw Exception('Failed to create schedule');
    return ScheduleModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<ScheduleModel> updateSchedule(int id, ScheduleModel schedule) async {
    final res = await http.put(
      Uri.parse('$_base/api/schedules/$id'),
      headers: _userHeaders,
      body: jsonEncode(schedule.toJson()),
    );
    if (res.statusCode != 200) throw Exception('Failed to update schedule');
    return ScheduleModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> disableSchedule(int id) async {
    final res = await http.patch(
      Uri.parse('$_base/api/schedules/$id/disable'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) throw Exception('Failed to disable schedule');
  }

  Future<void> enableSchedule(int id) async {
    final res = await http.patch(
      Uri.parse('$_base/api/schedules/$id/enable'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) throw Exception('Failed to enable schedule');
  }

  Future<void> deleteSchedule(int id) async {
    final res = await http.delete(
      Uri.parse('$_base/api/schedules/$id'),
      headers: _userHeaders,
    );
    if (res.statusCode != 204 && res.statusCode != 200) throw Exception('Failed to delete schedule');
  }

  Future<void> saveAiApiKey(String key) async {
    final res = await http.post(
      Uri.parse('$_base/api/ai/config/key'),
      headers: _userHeaders,
      body: jsonEncode({'apiKey': key}),
    );
    if (res.statusCode != 200) throw Exception('Lỗi lưu API Key');
  }

  Future<void> deleteAiApiKey() async {
    final res = await http.delete(
      Uri.parse('$_base/api/ai/config/key'),
      headers: _userHeaders,
    );
    if (res.statusCode != 204 && res.statusCode != 200) throw Exception('Lỗi xóa API Key');
  }

  Future<bool> getAiApiKeyStatus() async {
    final res = await http.get(
      Uri.parse('$_base/api/ai/config/key/status'),
      headers: _userHeaders,
    );
    if (res.statusCode != 200) return false;
    final data = jsonDecode(res.body);
    return data['hasCustomKey'] ?? false;
  }

  static String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
