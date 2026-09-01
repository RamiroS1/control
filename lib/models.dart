import 'package:flutter/material.dart';

enum TxType { expense, income }

class CategoryDef {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool incomeOnly;

  const CategoryDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.incomeOnly = false,
  });

  static const transporte = CategoryDef(
    id: 'transporte',
    name: 'Transporte',
    icon: Icons.directions_car,
    color: Color(0xFF3B5BDB),
  );
  static const serviciosApartamento = CategoryDef(
    id: 'servicios_apartamento',
    name: 'Servicios apartamento',
    icon: Icons.lightbulb_outline,
    color: Color(0xFF6C5CE0),
  );
  static const comida = CategoryDef(
    id: 'comida',
    name: 'Comida',
    icon: Icons.restaurant,
    color: Color(0xFFFF9F43),
  );
  static const arriendo = CategoryDef(
    id: 'arriendo',
    name: 'Arriendo',
    icon: Icons.apartment,
    color: Color(0xFF8E44AD),
  );
  static const tarjetaCredito = CategoryDef(
    id: 'tarjeta_credito',
    name: 'Tarjeta de credito',
    icon: Icons.credit_card,
    color: Color(0xFFE4573D),
  );
  static const deudas = CategoryDef(
    id: 'deudas',
    name: 'Deudas',
    icon: Icons.account_balance,
    color: Color(0xFFFF6B6B),
  );
  static const ahorros = CategoryDef(
    id: 'ahorros',
    name: 'Ahorros',
    icon: Icons.savings_outlined,
    color: Color(0xFF10855A),
  );
  static const ingresos = CategoryDef(
    id: 'ingresos',
    name: 'Ingresos',
    icon: Icons.account_balance_wallet,
    color: Color(0xFF00C9A7),
    incomeOnly: true,
  );
  static const saldoGuardado = CategoryDef(
    id: 'saldo_guardado',
    name: 'Saldo que ya tenia',
    icon: Icons.bookmark_outline,
    color: Color(0xFF5C6BC0),
    incomeOnly: true,
  );
  static const otros = CategoryDef(
    id: 'otros',
    name: 'Otros',
    icon: Icons.more_horiz,
    color: Color(0xFF95A5A6),
  );

  static const catalog = <CategoryDef>[
    transporte,
    serviciosApartamento,
    comida,
    arriendo,
    tarjetaCredito,
    deudas,
    ahorros,
    ingresos,
    saldoGuardado,
    otros,
  ];

  static List<CategoryDef> forType(TxType type) => type == TxType.income
      ? catalog.where((c) => c.incomeOnly || c.id == ahorros.id).toList()
      : catalog.where((c) => !c.incomeOnly).toList();

  static List<CategoryDef> get expenseCatalog =>
      catalog.where((c) => !c.incomeOnly).toList();

  static CategoryDef byId(String id) =>
      catalog.firstWhere((c) => c.id == id, orElse: () => otros);
}

class Account {
  String id;
  String name;
  String currency;
  double balance;
  Color color;
  String? templateId;

  Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.color,
    this.templateId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'balance': balance,
        'color': color.value,
        if (templateId != null) 'templateId': templateId,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        currency: j['currency'] as String,
        balance: (j['balance'] as num).toDouble(),
        color: Color(j['color'] as int),
        templateId: j['templateId'] as String?,
      );
}

class AccountTemplate {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const AccountTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const efectivo = AccountTemplate(
    id: 'efectivo',
    name: 'Dinero físico',
    icon: Icons.payments_outlined,
    color: Color(0xFF10855A),
  );
  static const nequi = AccountTemplate(
    id: 'nequi',
    name: 'Nequi',
    icon: Icons.phone_android,
    color: Color(0xFF6C0099),
  );
  static const bancolombia = AccountTemplate(
    id: 'bancolombia',
    name: 'Bancolombia',
    icon: Icons.account_balance,
    color: Color(0xFF2C2C2C),
  );
  static const daviplata = AccountTemplate(
    id: 'daviplata',
    name: 'DaviPlata',
    icon: Icons.smartphone,
    color: Color(0xFFE4002B),
  );

  static const catalog = [efectivo, nequi, bancolombia, daviplata];

  static AccountTemplate? byId(String? id) {
    if (id == null) return null;
    for (final t in catalog) {
      if (t.id == id) return t;
    }
    return null;
  }

  Account toAccount({double balance = 0, String currency = 'COP'}) => Account(
        id: 'acc_${id}_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        currency: currency,
        balance: balance,
        color: color,
        templateId: id,
      );

  static IconData iconFor(Account account) =>
      byId(account.templateId)?.icon ?? Icons.account_balance_wallet_outlined;
}

class Transaction {
  String id;
  String accountId;
  String categoryId;
  TxType type;
  double amount;
  DateTime date;
  String? note;
  /// false = nota de saldo arrastrado; no suma a ingresos ni al balance.
  bool countsAsIncome;

  Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    this.countsAsIncome = true,
  });

  bool get isBalanceNote => type == TxType.income && !countsAsIncome;

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'categoryId': categoryId,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
        if (!countsAsIncome) 'countsAsIncome': countsAsIncome,
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        categoryId: j['categoryId'] as String,
        type: TxType.values.byName(j['type'] as String),
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
        note: j['note'] as String?,
        countsAsIncome: j['countsAsIncome'] as bool? ?? true,
      );
}

class BalanceSnapshot {
  String id;
  DateTime date;
  double total;
  Map<String, double> byAccount;
  String? note;

  BalanceSnapshot({
    required this.id,
    required this.date,
    required this.total,
    required this.byAccount,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'total': total,
        'byAccount': byAccount,
        if (note != null) 'note': note,
      };

  factory BalanceSnapshot.fromJson(Map<String, dynamic> j) => BalanceSnapshot(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        total: (j['total'] as num).toDouble(),
        byAccount: (j['byAccount'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        note: j['note'] as String?,
      );
}

class BudgetPlan {
  int year;
  int month;
  double total;
  Map<String, double> byCategory;

  BudgetPlan({
    required this.year,
    required this.month,
    required this.total,
    required this.byCategory,
  });

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'total': total,
        'byCategory': byCategory,
      };

  factory BudgetPlan.fromJson(Map<String, dynamic> j) => BudgetPlan(
        year: j['year'] as int,
        month: j['month'] as int,
        total: (j['total'] as num).toDouble(),
        byCategory: (j['byCategory'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
}
