import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

// ===========================================================================
// CALCULOS FINANCIEROS
// ===========================================================================

class Finance {
  static bool sameMonth(DateTime d, int year, int month) =>
      d.year == year && d.month == month;

  static List<Transaction> forMonth(List<Transaction> txs, int year, int month) =>
      txs.where((t) => sameMonth(t.date, year, month)).toList();

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static List<Transaction> forDay(List<Transaction> txs, DateTime day) =>
      txs.where((t) => sameDay(t.date, day)).toList();

  static double expensesOnDay(List<Transaction> txs, DateTime day) =>
      forDay(txs, day)
          .where((t) => t.type == TxType.expense)
          .fold(0, (s, t) => s + t.amount);

  static double incomeOnDay(List<Transaction> txs, DateTime day) =>
      forDay(txs, day)
          .where((t) => t.type == TxType.income)
          .fold(0, (s, t) => s + t.amount);

  static Map<String, double> byCategoryForDay(
    List<Transaction> txs,
    DateTime day, {
    TxType type = TxType.expense,
  }) {
    final map = <String, double>{};
    for (final t in forDay(txs, day)) {
      if (t.type != type) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  static List<MapEntry<String, double>> sortedCategories(Map<String, double> byCat) {
    final entries = byCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  static double expenses(List<Transaction> txs, int year, int month) =>
      forMonth(txs, year, month)
          .where((t) => t.type == TxType.expense)
          .fold(0, (s, t) => s + t.amount);

  static double income(List<Transaction> txs, int year, int month) =>
      forMonth(txs, year, month)
          .where((t) => t.type == TxType.income)
          .fold(0, (s, t) => s + t.amount);

  static double net(List<Transaction> txs, int year, int month) =>
      income(txs, year, month) - expenses(txs, year, month);

  static Map<String, double> byCategory(
    List<Transaction> txs,
    int year,
    int month, {
    TxType type = TxType.expense,
  }) {
    final map = <String, double>{};
    for (final t in forMonth(txs, year, month)) {
      if (t.type != type) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  static int daysRemaining(DateTime now) {
    final end = DateTime(now.year, now.month + 1, 0);
    return end.difference(now).inDays + 1;
  }

  static double dailyAllowance(double remaining, int daysLeft) =>
      daysLeft > 0 ? remaining / daysLeft : 0;

  static double pctChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  }

  static List<double> monthlyTotals(
    List<Transaction> txs,
    DateTime anchor,
    int count, {
    TxType type = TxType.expense,
  }) {
    final out = <double>[];
    for (int i = count - 1; i >= 0; i--) {
      final d = DateTime(anchor.year, anchor.month - i, 1);
      final sum = forMonth(txs, d.year, d.month)
          .where((t) => t.type == type)
          .fold<double>(0, (s, t) => s + t.amount);
      out.add(sum);
    }
    return out;
  }

  static List<String> monthLabels(DateTime anchor, int count) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return List.generate(count, (i) {
      final d = DateTime(anchor.year, anchor.month - (count - 1 - i), 1);
      return names[d.month - 1];
    });
  }

  static double categoryAvailable(BudgetPlan plan, String catId, double spent) {
    final budgeted = plan.byCategory[catId] ?? 0;
    return budgeted - spent;
  }

  static double totalBudgeted(BudgetPlan plan) {
    if (plan.byCategory.isNotEmpty) {
      return plan.byCategory.values.fold(0, (s, v) => s + v);
    }
    return plan.total;
  }

  static double workingBalance(List<Account> accounts) =>
      accounts.fold(0, (s, a) => s + a.balance);
}

// ===========================================================================
// PERSISTENCIA LOCAL
// ===========================================================================

class Storage {
  static const dataVersion = 2;
  static const _accounts = 'control_accounts';
  static const _txs = 'control_transactions';
  static const _budgets = 'control_budgets';
  static const _version = 'control_data_version';

  /// Limpia datos mock viejos guardados en el navegador al actualizar la app.
  Future<void> migrateIfNeeded() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getInt(_version) ?? 0;
    if (stored < dataVersion) {
      await clearAll();
      await p.setInt(_version, dataVersion);
    }
  }

  Future<void> saveAccounts(List<Account> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_accounts, jsonEncode(list.map((a) => a.toJson()).toList()));
  }

  Future<List<Account>?> loadAccounts() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_accounts);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((j) => Account.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveTransactions(List<Transaction> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_txs, jsonEncode(list.map((t) => t.toJson()).toList()));
  }

  Future<List<Transaction>?> loadTransactions() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_txs);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((j) => Transaction.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> saveBudgets(List<BudgetPlan> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_budgets, jsonEncode(list.map((b) => b.toJson()).toList()));
  }

  Future<List<BudgetPlan>?> loadBudgets() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_budgets);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list.map((j) => BudgetPlan.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> clearAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_accounts);
    await p.remove(_txs);
    await p.remove(_budgets);
  }
}

// ===========================================================================
// IMPORT / EXPORT
// ===========================================================================

class DataPortability {
  static Map<String, dynamic> pack({
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<BudgetPlan> budgets,
  }) =>
      {
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'budgets': budgets.map((b) => b.toJson()).toList(),
      };

  static String encode({
    required List<Account> accounts,
    required List<Transaction> transactions,
    required List<BudgetPlan> budgets,
  }) =>
      const JsonEncoder.withIndent('  ').convert(pack(
            accounts: accounts,
            transactions: transactions,
            budgets: budgets,
          ));

  static ({
    List<Account> accounts,
    List<Transaction> transactions,
    List<BudgetPlan> budgets,
  }) decode(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final acc = (root['accounts'] as List)
        .map((j) => Account.fromJson(j as Map<String, dynamic>))
        .toList();
    final txs = (root['transactions'] as List)
        .map((j) => Transaction.fromJson(j as Map<String, dynamic>))
        .toList();
    final bud = (root['budgets'] as List)
        .map((j) => BudgetPlan.fromJson(j as Map<String, dynamic>))
        .toList();
    return (accounts: acc, transactions: txs, budgets: bud);
  }
}

// ===========================================================================
// DATOS DE DEMOSTRACION
// ===========================================================================

class Seed {
  static List<Account> accounts() => [
        Account(
            id: 'acc1',
            name: 'Cuenta principal',
            currency: 'USD',
            balance: 1800,
            color: const Color(0xFFFF9F43)),
        Account(
            id: 'acc2',
            name: 'Ahorros',
            currency: 'USD',
            balance: 1500,
            color: const Color(0xFF6C5CE0)),
      ];

  static BudgetPlan budget(DateTime now) => BudgetPlan(
        year: now.year,
        month: now.month,
        total: 0,
        byCategory: {
          'comida': 400,
          'transporte': 200,
          'arriendo': 850,
          'servicios_apartamento': 150,
          'tarjeta_credito': 300,
        },
      );

  static List<Transaction> transactions(DateTime now) {
    final y = now.year;
    final m = now.month;
    return [
      Transaction(
          id: 'tx1',
          accountId: 'acc1',
          categoryId: 'comida',
          type: TxType.expense,
          amount: 95.88,
          date: DateTime(y, m, 5),
          note: 'Supermercado'),
      Transaction(
          id: 'tx2',
          accountId: 'acc1',
          categoryId: 'transporte',
          type: TxType.expense,
          amount: 45,
          date: DateTime(y, m, 12),
          note: 'Transporte'),
      Transaction(
          id: 'tx3',
          accountId: 'acc2',
          categoryId: 'ingresos',
          type: TxType.income,
          amount: 3200,
          date: DateTime(y, m, 1),
          note: 'Nomina'),
      Transaction(
          id: 'tx4',
          accountId: 'acc1',
          categoryId: 'arriendo',
          type: TxType.expense,
          amount: 850,
          date: DateTime(y, m, 2),
          note: 'Arriendo'),
    ];
  }
}
