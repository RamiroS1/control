import 'package:flutter/material.dart';

enum TxType { expense, income }

class CategoryDef {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const CategoryDef({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const food = CategoryDef(
      id: 'food', name: 'Comida', icon: Icons.restaurant, color: Color(0xFFFF9F43));
  static const transport = CategoryDef(
      id: 'transport', name: 'Transporte', icon: Icons.directions_car, color: Color(0xFF3B5BDB));
  static const education = CategoryDef(
      id: 'education', name: 'Educacion', icon: Icons.school, color: Color(0xFF6C5CE0));
  static const entertainment = CategoryDef(
      id: 'entertainment',
      name: 'Entretenimiento',
      icon: Icons.movie,
      color: Color(0xFF00C9A7));
  static const shopping = CategoryDef(
      id: 'shopping', name: 'Compras', icon: Icons.shopping_bag, color: Color(0xFFE4573D));
  static const health = CategoryDef(
      id: 'health', name: 'Salud', icon: Icons.favorite, color: Color(0xFFFF6B6B));
  static const home = CategoryDef(
      id: 'home', name: 'Hogar', icon: Icons.home, color: Color(0xFF8E44AD));
  static const salary = CategoryDef(
      id: 'salary', name: 'Salario', icon: Icons.account_balance_wallet, color: Color(0xFF10855A));
  static const other = CategoryDef(
      id: 'other', name: 'Otros', icon: Icons.more_horiz, color: Color(0xFF95A5A6));

  static const catalog = <CategoryDef>[
    food,
    transport,
    education,
    entertainment,
    shopping,
    health,
    home,
    salary,
    other,
  ];

  static CategoryDef byId(String id) =>
      catalog.firstWhere((c) => c.id == id, orElse: () => other);
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
