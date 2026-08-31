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

  Account({
    required this.id,
    required this.name,
    required this.currency,
    required this.balance,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'currency': currency,
        'balance': balance,
        'color': color.value,
      };

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        currency: j['currency'] as String,
        balance: (j['balance'] as num).toDouble(),
        color: Color(j['color'] as int),
      );
}

class Transaction {
  String id;
  String accountId;
  String categoryId;
  TxType type;
  double amount;
  DateTime date;
  String? note;

  Transaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'categoryId': categoryId,
        'type': type.name,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        categoryId: j['categoryId'] as String,
        type: TxType.values.byName(j['type'] as String),
        amount: (j['amount'] as num).toDouble(),
        date: DateTime.parse(j['date'] as String),
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
