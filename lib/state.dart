import 'package:flutter/material.dart';

import 'models.dart';
import 'services.dart';

class AppState extends ChangeNotifier {
  final Storage storage = Storage();
  final List<Account> accounts = [];
  final List<Transaction> transactions = [];
  final List<BudgetPlan> budgets = [];
  final List<BalanceSnapshot> balanceSnapshots = [];
  DateTime focusMonth = DateTime.now();
  bool loaded = false;

  BudgetPlan? budgetFor(DateTime d) {
    for (final b in budgets) {
      if (b.year == d.year && b.month == d.month) return b;
    }
    return null;
  }

  Future<void> init() async {
    await storage.migrateIfNeeded();
    final acc = await storage.loadAccounts();
    final txs = await storage.loadTransactions();
    final bud = await storage.loadBudgets();
    final snaps = await storage.loadBalanceSnapshots();
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
      balanceSnapshots
        ..clear()
        ..addAll(snaps);
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
    balanceSnapshots.clear();
    await storage.clearAll();
    notifyListeners();
  }

  String exportJson() => DataPortability.encode(
        accounts: accounts,
        transactions: transactions,
        budgets: budgets,
        snapshots: balanceSnapshots,
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
    balanceSnapshots
      ..clear()
      ..addAll(data.snapshots);
    await persist();
    notifyListeners();
  }

  void addAccount(Account account) {
    accounts.add(account);
    persist();
    notifyListeners();
  }

  bool hasAccountTemplate(String templateId) =>
      accounts.any((a) => a.templateId == templateId);

  void addAccountFromTemplate(AccountTemplate template, {double balance = 0}) {
    if (hasAccountTemplate(template.id)) return;
    addAccount(template.toAccount(balance: balance));
  }

  void addSuggestedAccounts() {
    for (final t in AccountTemplate.catalog) {
      addAccountFromTemplate(t);
    }
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
    await storage.saveBalanceSnapshots(balanceSnapshots);
  }

  void setFocusMonth(DateTime d) {
    focusMonth = DateTime(d.year, d.month);
    notifyListeners();
  }

  void addTransaction(Transaction t) {
    final accIndex = accounts.indexWhere((a) => a.id == t.accountId);
    if (accIndex < 0) {
      throw StateError('Cuenta no encontrada');
    }
    transactions.insert(0, t);
    final acc = accounts[accIndex];
    if (t.type == TxType.expense) {
      acc.balance -= t.amount;
    } else if (t.countsAsIncome) {
      acc.balance += t.amount;
    }
    persist();
    notifyListeners();
  }

  void saveBalanceSnapshot({String? note, double? total}) {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final accountTotal = Finance.workingBalance(accounts);
    final target = total ?? accountTotal;
    if ((target - accountTotal).abs() > 0.01) {
      _syncAccountsToTotal(target);
    }
    final byAccount = {for (final a in accounts) a.id: a.balance};
    balanceSnapshots.removeWhere((s) => Finance.sameDay(s.date, day));
    balanceSnapshots.insert(
      0,
      BalanceSnapshot(
        id: 'snap_${now.millisecondsSinceEpoch}',
        date: day,
        total: target,
        byAccount: byAccount,
        note: note,
      ),
    );
    persist();
    notifyListeners();
  }

  void _syncAccountsToTotal(double target) {
    if (accounts.isEmpty) return;
    final current = Finance.workingBalance(accounts);
    if ((current - target).abs() < 0.01) return;
    if (current == 0) {
      accounts[0].balance = target;
      return;
    }
    for (final a in accounts) {
      a.balance = a.balance * target / current;
    }
    final drift = target - Finance.workingBalance(accounts);
    if (drift.abs() > 0.01) {
      accounts.last.balance += drift;
    }
  }

  void restoreBalanceSnapshot(BalanceSnapshot snapshot) {
    for (final entry in snapshot.byAccount.entries) {
      final i = accounts.indexWhere((a) => a.id == entry.key);
      if (i >= 0) accounts[i].balance = entry.value;
    }
    persist();
    notifyListeners();
  }

  BalanceSnapshot? yesterdaySnapshot() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    return Finance.latestSnapshotBefore(balanceSnapshots, todayStart);
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
    return BudgetPlan(
      year: focusMonth.year,
      month: focusMonth.month,
      total: 0,
      byCategory: {},
    );
  }

  double budgetRemaining() {
    final flow = Finance.monthFlow(
      plan: currentBudget(),
      txs: transactions,
      year: focusMonth.year,
      month: focusMonth.month,
      today: DateTime.now(),
    );
    return flow.monthAvailable;
  }
}

class Store extends InheritedNotifier<AppState> {
  const Store({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Store>()!.notifier!;
}
