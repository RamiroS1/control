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

  test('daily tracking', () {
    final dayTxs = [
      Transaction(
          id: 'd1',
          accountId: 'a',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 20,
          date: DateTime(2026, 8, 31, 14)),
      Transaction(
          id: 'd2',
          accountId: 'a',
          categoryId: 'ingresos',
          type: TxType.income,
          amount: 100,
          date: DateTime(2026, 8, 31, 9)),
    ];
    final day = DateTime(2026, 8, 31);
    expect(Finance.expensesOnDay(dayTxs, day), 20);
    expect(Finance.incomeOnDay(dayTxs, day), 100);
    expect(Finance.byCategoryForDay(dayTxs, day)['comida'], 20);
  });

  test('sorted categories', () {
    final sorted = Finance.sortedCategories({'comida': 10, 'transporte': 30});
    expect(sorted.first.key, 'transporte');
  });

  test('month flow without budget uses income', () {
    final plan = BudgetPlan(year: 2026, month: 8, total: 0, byCategory: {});
    final txs = [
      Transaction(
          id: 'i1',
          accountId: 'a',
          categoryId: 'ingresos',
          type: TxType.income,
          amount: 29000,
          date: DateTime(2026, 8, 31)),
      Transaction(
          id: 'e1',
          accountId: 'a',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 14000,
          date: DateTime(2026, 8, 31)),
    ];
    final flow = Finance.monthFlow(
      plan: plan,
      txs: txs,
      year: 2026,
      month: 8,
      today: DateTime(2026, 8, 31),
    );
    expect(flow.usesBudget, false);
    expect(flow.monthAvailable, 15000);
    expect(flow.dailyBudget, 15000);
    expect(flow.referenceTotal, 29000);
  });

  test('month flow with budget', () {
    final plan = BudgetPlan(
        year: 2026, month: 8, total: 5000, byCategory: {'comida': 5000});
    final txs = [
      Transaction(
          id: 'e1',
          accountId: 'a',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 1000,
          date: DateTime(2026, 8, 15)),
    ];
    final flow = Finance.monthFlow(
      plan: plan,
      txs: txs,
      year: 2026,
      month: 8,
      today: DateTime(2026, 8, 15),
    );
    expect(flow.usesBudget, true);
    expect(flow.monthAvailable, 4000);
    expect(flow.referenceTotal, 5000);
  });

  test('monthly net totals and labels', () {
    final txs = [
      Transaction(
          id: 'i1',
          accountId: 'a',
          categoryId: 'ingresos',
          type: TxType.income,
          amount: 29000,
          date: DateTime(2026, 8, 31)),
      Transaction(
          id: 'e1',
          accountId: 'a',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 14000,
          date: DateTime(2026, 8, 31)),
    ];
    final anchor = DateTime(2026, 8, 31);
    final nets = Finance.monthlyNetTotals(txs, anchor, 3);
    expect(nets.length, 3);
    expect(nets[2], 15000);
    expect(nets[0], 0);

    final labels = Finance.monthLabels(anchor, 3);
    expect(labels, ['Jun', 'Jul', 'Ago']);
  });

  test('account month stats', () {
    final txs = [
      Transaction(
          id: '1',
          accountId: 'acc1',
          categoryId: 'ingresos',
          type: TxType.income,
          amount: 100,
          date: DateTime(2026, 8, 1)),
      Transaction(
          id: '2',
          accountId: 'acc1',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 40,
          date: DateTime(2026, 8, 2)),
      Transaction(
          id: '3',
          accountId: 'acc2',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 10,
          date: DateTime(2026, 8, 3)),
    ];
    expect(Finance.accountIncome(txs, 'acc1', 2026, 8), 100);
    expect(Finance.accountExpenses(txs, 'acc1', 2026, 8), 40);
    expect(Finance.accountExpenses(txs, 'acc2', 2026, 8), 10);
  });

  test('carry over income excluded from totals', () {
    final txs = [
      Transaction(
          id: '1',
          accountId: 'a',
          categoryId: 'ingresos',
          type: TxType.income,
          amount: 29000,
          date: DateTime(2026, 8, 31)),
      Transaction(
          id: '2',
          accountId: 'a',
          categoryId: 'saldo_guardado',
          type: TxType.income,
          amount: 15000,
          date: DateTime(2026, 9, 1),
          countsAsIncome: false),
    ];
    expect(Finance.income(txs, 2026, 8), 29000);
    expect(Finance.income(txs, 2026, 9), 0);
  });
}
