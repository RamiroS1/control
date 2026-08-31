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
    } else {
      final now = DateTime.now();
      accounts.addAll(Seed.accounts());
      transactions.addAll(Seed.transactions(now));
      budgets.add(Seed.budget(now));
      await persist();
    }
    loaded = true;
    notifyListeners();
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
