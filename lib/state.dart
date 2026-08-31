import 'package:flutter/material.dart';

import 'models.dart';
import 'services.dart';

class AppState extends ChangeNotifier {
  final Storage storage = Storage();
  final List<Account> accounts = [];
  final List<Transaction> transactions = [];
  final List<BudgetPlan> budgets = [];
  DateTime focusMonth = DateTime.now();
  bool loaded = false;

  BudgetPlan? budgetFor(DateTime d) {
    for (final b in budgets) {
      if (b.year == d.year && b.month == d.month) return b;
    }
    return null;
  }

  Future<void> init() async {
    final acc = await storage.loadAccounts();
    final txs = await storage.loadTransactions();
    final bud = await storage.loadBudgets();
    if (acc != null && txs != null) {
      accounts
        ..clear()
        ..addAll(acc);
      transactions
        ..clear()
        ..addAll(txs);
      if (bud != null) {
        budgets
          ..clear()
          ..addAll(bud);
      }
    }
    loaded = true;
    notifyListeners();
  }

  Future<void> loadDemoData() async {
    final now = DateTime.now();
    accounts
      ..clear()
      ..addAll(Seed.accounts());
    transactions
      ..clear()
      ..addAll(Seed.transactions(now));
    budgets
      ..clear()
      ..add(Seed.budget(now));
    await persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    accounts.clear();
    transactions.clear();
    budgets.clear();
    await storage.clearAll();
    notifyListeners();
  }

  String exportJson() => DataPortability.encode(
        accounts: accounts,
        transactions: transactions,
        budgets: budgets,
      );

  Future<void> importJson(String raw) async {
    final data = DataPortability.decode(raw);
    accounts
      ..clear()
      ..addAll(data.accounts);
    transactions
      ..clear()
      ..addAll(data.transactions);
    budgets
      ..clear()
      ..addAll(data.budgets);
    await persist();
    notifyListeners();
  }

  void addAccount(Account account) {
    accounts.add(account);
    persist();
    notifyListeners();
  }

  void updateAccount(Account account) {
    final i = accounts.indexWhere((a) => a.id == account.id);
    if (i >= 0) {
      accounts[i] = account;
      persist();
      notifyListeners();
    }
  }

  Future<void> persist() async {
    await storage.saveAccounts(accounts);
    await storage.saveTransactions(transactions);
    await storage.saveBudgets(budgets);
  }

  void setFocusMonth(DateTime d) {
    focusMonth = DateTime(d.year, d.month);
    notifyListeners();
  }

  void addTransaction(Transaction t) {
    transactions.insert(0, t);
    final acc = accounts.firstWhere((a) => a.id == t.accountId);
    if (t.type == TxType.expense) {
      acc.balance -= t.amount;
    } else {
      acc.balance += t.amount;
    }
    persist();
    notifyListeners();
  }

  void updateBudget(BudgetPlan plan) {
    budgets.removeWhere((b) => b.year == plan.year && b.month == plan.month);
    budgets.add(plan);
    persist();
    notifyListeners();
  }

  double monthExpenses() =>
      Finance.expenses(transactions, focusMonth.year, focusMonth.month);

  double monthIncome() =>
      Finance.income(transactions, focusMonth.year, focusMonth.month);

  BudgetPlan currentBudget() {
    final existing = budgetFor(focusMonth);
    if (existing != null) return existing;
    final plan = BudgetPlan(
      year: focusMonth.year,
      month: focusMonth.month,
      total: 2500,
      byCategory: {},
    );
    budgets.add(plan);
    return plan;
  }

  double budgetRemaining() {
    final plan = currentBudget();
    final total = Finance.totalBudgeted(plan);
    return total - monthExpenses();
  }
}

class Store extends InheritedNotifier<AppState> {
  const Store({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Store>()!.notifier!;
}
