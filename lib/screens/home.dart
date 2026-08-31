import 'package:flutter/material.dart';

import '../core.dart';
import '../services.dart';
import '../state.dart';
import '../widgets/budget_card.dart';
import '../widgets/flow_cards.dart';
import '../widgets/tx_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final today = DateTime.now();
    final now = state.focusMonth;
    final spent = state.monthExpenses();
    final income = state.monthIncome();
    final plan = state.currentBudget();
    final total = Finance.totalBudgeted(plan);
    final remaining = total - spent;
    final daysLeft = Finance.daysRemaining(today);
    final dailyBudget = Finance.dailyAllowance(remaining, daysLeft);
    final spentToday = Finance.expensesOnDay(state.transactions, today);
    final incomeToday = Finance.incomeOnDay(state.transactions, today);
    final balance = Finance.workingBalance(state.accounts);
    final byCat = Finance.byCategory(
      state.transactions,
      now.year,
      now.month,
    );
    final todayByCat = Finance.byCategoryForDay(state.transactions, today);
    final recent = state.transactions.take(8).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const H1('Inicio'),
          const SizedBox(height: 16),
          DailySummaryCard(
            dailyBudget: dailyBudget,
            spentToday: spentToday,
            incomeToday: incomeToday,
            balanceTotal: balance,
          ),
          const SizedBox(height: 16),
          MonthFlowCard(
            income: income,
            expenses: spent,
            net: income - spent,
          ),
          const SizedBox(height: 16),
          BudgetCard(
            label: 'Presupuesto ${now.year}',
            month: _monthName(now.month),
            remaining: remaining,
            total: total,
            daysLeft: daysLeft,
            daily: dailyBudget,
          ),
          if (todayByCat.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Label('gastos de hoy'),
            const SizedBox(height: 10),
            CategoryBreakdown(
              byCategory: todayByCat,
              emptyMessage: 'Sin gastos hoy',
            ),
          ],
          const SizedBox(height: 20),
          const Label('gastos del mes por categoria'),
          const SizedBox(height: 10),
          CategoryBreakdown(byCategory: byCat),
          const SizedBox(height: 20),
          const Label('movimientos recientes'),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const Glass(
              child: Text(
                'Sin movimientos. Toca + para registrar una entrada o un gasto.',
                style: TextStyle(color: T.ink45, fontSize: 13),
              ),
            )
          else
            ...recent.map((t) => TxRow(tx: t)),
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
