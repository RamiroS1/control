import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../widgets/budget_card.dart';
import 'edit_budget.dart';

class BudgetDetailScreen extends StatelessWidget {
  const BudgetDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final now = state.focusMonth;
    final plan = state.currentBudget();
    final spent = state.monthExpenses();
    final flow = Finance.monthFlow(
      plan: plan,
      txs: state.transactions,
      year: now.year,
      month: now.month,
      today: DateTime.now(),
    );
    final byCat = Finance.byCategory(
        state.transactions, now.year, now.month);

    final categories = plan.byCategory.keys.isNotEmpty
        ? plan.byCategory.keys.toList()
        : CategoryDef.expenseCatalog.map((c) => c.id).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              const Expanded(child: H1('Presupuesto')),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: T.ink45),
                tooltip: 'Editar presupuesto',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditBudgetScreen()),
                ),
              ),
              _MonthChip(
                label: _monthName(now.month),
                onPrev: () => state.setFocusMonth(
                    DateTime(now.year, now.month - 1)),
                onNext: () => state.setFocusMonth(
                    DateTime(now.year, now.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          BudgetCard(
            label: flow.usesBudget ? 'Presupuesto ${now.year}' : 'Flujo ${now.year}',
            month: _monthName(now.month),
            remaining: flow.monthAvailable,
            total: flow.referenceTotal,
            daysLeft: flow.daysLeft,
            daily: flow.dailyBudget,
            referenceLabel: flow.referenceLabel,
          ),
          const SizedBox(height: 16),
          Glass(
            onTap: () {},
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: T.go.withOpacity(.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.savings, color: T.go),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Crear meta de ahorro',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text('Planifica y alcanza tus objetivos',
                          style: TextStyle(fontSize: 12, color: T.ink45)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: T.ink45),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Label('categorias'),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: const [
                    Expanded(
                        child: Text('Categoria',
                            style: TextStyle(fontSize: 11, color: T.ink45))),
                    SizedBox(
                        width: 72,
                        child: Text('Presup.',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: T.ink45))),
                    SizedBox(
                        width: 72,
                        child: Text('Disp.',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, color: T.ink45))),
                  ],
                ),
                const Divider(height: 16),
                ...categories.map((id) {
                  final cat = CategoryDef.byId(id);
                  final budgeted = plan.byCategory[id] ?? 0;
                  final catSpent = byCat[id] ?? 0;
                  final avail = budgeted - catSpent;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: cat.color.withOpacity(.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(cat.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 13))),
                        SizedBox(
                          width: 72,
                          child: Text(moneyFull(budgeted),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontFamily: T.mono, fontSize: 12)),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(moneyFull(avail),
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontFamily: T.mono,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: avail < 0 ? T.clay : T.go)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    return names[m - 1];
  }
}

class _MonthChip extends StatelessWidget {
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  const _MonthChip({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: onPrev,
          color: T.ink45,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: T.edge),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: onNext,
          color: T.ink45,
        ),
      ],
    );
  }
}
