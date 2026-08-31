import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:control/models.dart';
import 'package:control/services.dart';

void main() {
  final txs = [
    Transaction(
        id: '1',
        accountId: 'a',
        categoryId: 'comida',
        type: TxType.expense,
        amount: 50,
        date: DateTime(2026, 6, 5)),
    Transaction(
        id: '2',
        accountId: 'a',
        categoryId: 'transporte',
        type: TxType.expense,
        amount: 30,
        date: DateTime(2026, 6, 10)),
    Transaction(
        id: '3',
        accountId: 'a',
        categoryId: 'ingresos',
        type: TxType.income,
        amount: 2000,
        date: DateTime(2026, 6, 1)),
    Transaction(
        id: '4',
        accountId: 'a',
        categoryId: 'comida',
        type: TxType.expense,
        amount: 40,
        date: DateTime(2026, 5, 20)),
  ];

  test('monthly expenses', () {
    expect(Finance.expenses(txs, 2026, 6), 80);
    expect(Finance.expenses(txs, 2026, 5), 40);
  });

  test('monthly income', () {
    expect(Finance.income(txs, 2026, 6), 2000);
  });

  test('by category', () {
    final map = Finance.byCategory(txs, 2026, 6);
    expect(map['comida'], 50);
    expect(map['transporte'], 30);
  });

  test('pct change', () {
    expect(Finance.pctChange(80, 40), 100);
    expect(Finance.pctChange(40, 80), -50);
  });

  test('daily allowance', () {
    expect(Finance.dailyAllowance(300, 10), 30);
    expect(Finance.dailyAllowance(300, 0), 0);
  });

  test('days remaining', () {
    expect(Finance.daysRemaining(DateTime(2026, 6, 15)), 16);
  });

  test('expense categories', () {
    expect(CategoryDef.expenseCatalog.length, 8);
    expect(CategoryDef.forType(TxType.income).any((c) => c.id == 'ingresos'), true);
  });

  test('data portability roundtrip', () {
    final accounts = [
      Account(
        id: 'a1',
        name: 'Principal',
        currency: 'USD',
        balance: 100,
        color: const Color(0xFF3B5BDB),
      ),
    ];
    final budgets = [
      BudgetPlan(year: 2026, month: 8, total: 500, byCategory: {'comida': 200}),
    ];
    final raw = DataPortability.encode(
      accounts: accounts,
      transactions: txs,
      budgets: budgets,
    );
    final decoded = DataPortability.decode(raw);
    expect(decoded.accounts.first.name, 'Principal');
    expect(decoded.budgets.first.byCategory['comida'], 200);
  });
}
