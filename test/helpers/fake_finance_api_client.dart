import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/models/ai_assistant_response.dart';
import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';
import 'package:prm393_finance_project/src/core/network/finance_api_client.dart';

class FakeFinanceApiClient implements FinanceApiClient {
  final List<FinancialEntryModel> fakeEntries;
  final List<AccountModel> fakeAccounts;
  final List<CategoryModel> fakeCategories;

  FakeFinanceApiClient({
    List<FinancialEntryModel>? entries,
    List<AccountModel>? accounts,
    List<CategoryModel>? categories,
  }) : fakeEntries =
           entries ??
           [
             FinancialEntryModel(
               id: 1,
               amount: 50000,
               categoryId: 1,
               categoryName: 'Ăn uống',
               transactionDate: DateTime(2025, 3, 15),
               type: 'EXPENSE',
               accountId: 1,
               note: 'Bữa trưa',
               tags: ['#food'],
             ),
             FinancialEntryModel(
               id: 2,
               amount: 1000000,
               categoryId: 2,
               categoryName: 'Lương',
               transactionDate: DateTime(2025, 3, 1),
               type: 'INCOME',
               accountId: 1,
               note: 'Lương tháng 3',
             ),
           ],
       fakeAccounts =
           accounts ??
           [
             AccountModel(id: 1, name: 'Ví tiền mặt', balance: 950000),
             AccountModel(id: 2, name: 'Ngân hàng', balance: 5000000),
           ],
       fakeCategories =
           categories ??
           [
             CategoryModel(
               id: 1,
               name: 'Ăn uống',
               iconName: 'restaurant',
               colorHex: '#FF5722',
               sortOrder: 1,
             ),
             CategoryModel(
               id: 2,
               name: 'Lương',
               iconName: 'work',
               colorHex: '#4CAF50',
               sortOrder: 2,
             ),
             CategoryModel(
               id: 3,
               name: 'Di chuyển',
               iconName: 'directions_car',
               colorHex: '#2196F3',
               sortOrder: 3,
             ),
           ];

  @override
  Future<List<FinancialEntryModel>> getEntries({
    DateTime? from,
    DateTime? to,
    String? tag,
  }) async {
    if (tag != null && tag.isNotEmpty) {
      return fakeEntries.where((e) => e.tags?.contains(tag) ?? false).toList();
    }
    return fakeEntries;
  }

  @override
  Future<List<AccountModel>> getAccounts() async => fakeAccounts;

  @override
  Future<List<CategoryModel>> getCategories() async => fakeCategories;

  @override
  Future<FinancialEntryModel> createEntry(FinancialEntryModel entry) async {
    final newEntry = FinancialEntryModel(
      id: fakeEntries.length + 1,
      amount: entry.amount,
      categoryId: entry.categoryId,
      categoryName: entry.categoryName,
      transactionDate: entry.transactionDate,
      type: entry.type,
      accountId: entry.accountId,
      note: entry.note,
      tags: entry.tags,
    );
    fakeEntries.add(newEntry);
    return newEntry;
  }

  @override
  Future<FinancialEntryModel> updateEntry(
    int id,
    FinancialEntryModel entry,
  ) async {
    final idx = fakeEntries.indexWhere((e) => e.id == id);
    if (idx == -1) throw Exception('Entry not found: $id');
    final updated = FinancialEntryModel(
      id: id,
      amount: entry.amount,
      categoryId: entry.categoryId,
      categoryName: entry.categoryName,
      transactionDate: entry.transactionDate,
      type: entry.type,
      accountId: entry.accountId,
      note: entry.note,
      tags: entry.tags,
    );
    fakeEntries[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteEntry(int id) async {
    fakeEntries.removeWhere((e) => e.id == id);
  }

  @override
  Future<AccountModel> createAccount(String name, double balance) async {
    final acc = AccountModel(
      id: fakeAccounts.length + 1,
      name: name,
      balance: balance,
    );
    fakeAccounts.add(acc);
    return acc;
  }

  @override
  Future<AccountModel> updateAccount(
    int id,
    String name,
    double balance,
  ) async {
    final idx = fakeAccounts.indexWhere((a) => a.id == id);
    if (idx == -1) throw Exception('Account not found: $id');
    final updated = AccountModel(id: id, name: name, balance: balance);
    fakeAccounts[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteAccount(int id) async {
    fakeAccounts.removeWhere((a) => a.id == id);
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final created = CategoryModel(
      id: fakeCategories.length + 1,
      name: category.name,
      iconName: category.iconName,
      colorHex: category.colorHex,
      sortOrder: category.sortOrder,
    );
    fakeCategories.add(created);
    return created;
  }

  @override
  Future<CategoryModel> updateCategory(int id, CategoryModel category) async {
    final idx = fakeCategories.indexWhere((c) => c.id == id);
    if (idx == -1) throw Exception('Category not found: $id');
    final updated = CategoryModel(
      id: id,
      name: category.name,
      iconName: category.iconName,
      colorHex: category.colorHex,
      sortOrder: category.sortOrder,
    );
    fakeCategories[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteCategory(int id) async {
    fakeCategories.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> uploadImage(int id, String filePath) async {
    // No-op trong test
  }

  @override
  Future<void> uploadImageBytes(
    int id,
    List<int> bytes,
    String filename,
  ) async {
    // No-op trong test
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    return {'id': 1, 'email': email, 'displayName': 'Test User'};
  }

  @override
  Future<Map<String, dynamic>> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    return {'id': 1, 'email': email, 'displayName': displayName ?? 'Test User'};
  }

  @override
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    return {'id': 1, 'email': 'test@gmail.com', 'displayName': 'Google User'};
  }

  @override
  Future<AiAssistantResponse> askAssistant(
    String message, {
    String? conversationId,
    int? accountId,
  }) async {
    return AiAssistantResponse(
      reply: 'Đây là câu trả lời giả lập từ AI',
      intent: 'UNKNOWN',
      conversationId: conversationId ?? 'fake-conv-id',
    );
  }
}
