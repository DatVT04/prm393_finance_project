import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_finance_project/src/core/models/account_model.dart';
import 'package:prm393_finance_project/src/core/models/category_model.dart';
import 'package:prm393_finance_project/src/core/models/financial_entry_model.dart';

void main() {
  group('FinancialEntryModel', () {
    test('fromJson parses minimal JSON', () {
      final json = {
        'id': 1,
        'amount': 100000,
        'note': 'Test',
        'categoryId': 1,
        'categoryName': 'Ăn uống',
        'transactionDate': '2025-03-15T00:00:00.000',
        'type': 'EXPENSE',
        'accountId': 1,
      };
      final m = FinancialEntryModel.fromJson(json);
      expect(m.id, 1);
      expect(m.amount, 100000);
      expect(m.note, 'Test');
      expect(m.categoryId, 1);
      expect(m.categoryName, 'Ăn uống');
      expect(m.type, 'EXPENSE');
      expect(m.accountId, 1);
      expect(m.transactionDate.year, 2025);
      expect(m.transactionDate.month, 3);
      expect(m.transactionDate.day, 15);
    });


    test('toCreateJson produces valid API payload', () {
      final m = FinancialEntryModel(
        id: 1,
        amount: 100000,
        categoryId: 1,
        transactionDate: DateTime(2025, 3, 15),
        type: 'EXPENSE',
        accountId: 1,
        note: 'Note',
      );
      final json = m.toCreateJson();
      expect(json['amount'], 100000);
      expect(json['categoryId'], 1);
      expect(json['accountId'], 1);
      expect(json['type'], 'EXPENSE');
      expect(json['note'], 'Note');
      expect(json['transactionDate'], '2025-03-15');
    });
  });

  group('AccountModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Ví tiền mặt',
        'balance': 5000000.5,
        'iconName': 'wallet',
        'colorHex': '#00FF00',
      };
      final m = AccountModel.fromJson(json);
      expect(m.id, 1);
      expect(m.name, 'Ví tiền mặt');
      expect(m.balance, 5000000.5);
      expect(m.iconName, 'wallet');
      expect(m.colorHex, '#00FF00');
    });

    test('toJson excludes id', () {
      final m = AccountModel(id: 1, name: 'Test', balance: 100);
      final json = m.toJson();
      expect(json['name'], 'Test');
      expect(json['balance'], 100);
      expect(json.containsKey('id'), false);
    });
  });

  group('CategoryModel', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Ăn uống',
        'iconName': 'restaurant',
        'colorHex': '#FF0000',
      };
      final m = CategoryModel.fromJson(json);
      expect(m.id, 1);
      expect(m.name, 'Ăn uống');
      expect(m.iconName, 'restaurant');
      expect(m.colorHex, '#FF0000');
    });

    test('fromJson uses empty string when name is null', () {
      final m = CategoryModel.fromJson({'id': 1});
      expect(m.name, '');
    });
  });
}
