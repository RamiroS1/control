import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';

class DailySummaryCard extends StatelessWidget {
  final double dailyBudget;
  final double spentToday;
  final double incomeToday;
  final double balanceTotal;

  const DailySummaryCard({
    super.key,
    required this.dailyBudget,
    required this.spentToday,
    required this.incomeToday,
    required this.balanceTotal,
  });

  double get remainingToday => dailyBudget - spentToday;

  @override
  Widget build(BuildContext context) {
    final pct = dailyBudget > 0 ? (spentToday / dailyBudget).clamp(0.0, 1.0) : 0.0;

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: T.volt.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Hoy',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: T.volt)),
              ),
              const Spacer(),
              Text('Balance ${moneyFull(balanceTotal)}',
                  style: const TextStyle(fontSize: 11, color: T.ink45)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Puedes gastar hoy',
                  value: moneyFull(dailyBudget),
                  color: T.volt,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Gastaste hoy',
                  value: moneyFull(spentToday),
                  color: T.clay,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Te quedan hoy',
                  value: moneyFull(remainingToday),
                  color: remainingToday >= 0 ? T.go : T.clay,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Entradas hoy',
                  value: moneyFull(incomeToday),
                  color: T.go,
                ),
              ),
            ],
          ),
          if (dailyBudget > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 8,
                backgroundColor: T.hair,
                valueColor: AlwaysStoppedAnimation(
                  pct >= 1 ? T.clay : T.volt,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(pct * 100).toStringAsFixed(0)}% del presupuesto diario usado',
              style: const TextStyle(fontSize: 11, color: T.ink45),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Define tu presupuesto mensual para ver cuanto puedes gastar por dia.',
                style: TextStyle(fontSize: 12, color: T.ink45),
              ),
            ),
        ],
      ),
    );
  }
}

class MonthFlowCard extends StatelessWidget {
  final double income;
  final double expenses;
  final double net;

  const MonthFlowCard({
    super.key,
    required this.income,
    required this.expenses,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label('este mes'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(label: 'Entradas', value: moneyFull(income), color: T.go),
              ),
              Expanded(
                child: _Stat(label: 'Gastos', value: moneyFull(expenses), color: T.clay),
              ),
              Expanded(
                child: _Stat(
                  label: 'Neto',
                  value: moneyFull(net),
                  color: net >= 0 ? T.go : T.clay,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CategoryBreakdown extends StatelessWidget {
  final Map<String, double> byCategory;
  final String emptyMessage;

  const CategoryBreakdown({
    super.key,
    required this.byCategory,
    this.emptyMessage = 'Sin gastos registrados',
  });

  @override
  Widget build(BuildContext context) {
    final entries = Finance.sortedCategories(byCategory);
    if (entries.isEmpty) {
      return Glass(
        child: Text(emptyMessage, style: const TextStyle(color: T.ink45, fontSize: 13)),
      );
    }

    final max = entries.first.value;

    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: entries.map((e) {
          final cat = CategoryDef.byId(e.key);
          final pct = max > 0 ? e.value / max : 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(cat.icon, color: cat.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                    Text(moneyFull(e.value),
                        style: const TextStyle(
                            fontFamily: T.mono, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: T.hair,
                    valueColor: AlwaysStoppedAnimation(cat.color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: T.ink45)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontFamily: T.mono,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color)),
      ],
    );
  }
}
