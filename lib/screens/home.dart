import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../widgets/accounts_breakdown.dart';
import '../widgets/balance_reminder_card.dart';
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
    final flow = Finance.monthFlow(
      plan: state.currentBudget(),
      txs: state.transactions,
      year: now.year,
      month: now.month,
      today: today,
    );
    final incomeToday = Finance.incomeOnDay(state.transactions, today);
    final todayNet = Finance.netOnDay(state.transactions, today);
    final balance = Finance.workingBalance(state.accounts);
    final yesterdaySnap = state.yesterdaySnapshot();
    final expectedFromYesterday = Finance.expectedBalanceFromSnapshot(
      previousSnapshot: yesterdaySnap,
      txs: state.transactions,
      day: today,
    );
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
            flow: flow,
            incomeToday: incomeToday,
            balanceTotal: balance,
          ),
          const SizedBox(height: 16),
          BalanceReminderCard(
            snapshots: state.balanceSnapshots,
            accounts: state.accounts,
            currentTotal: balance,
            monthNet: flow.monthAvailable,
            todayNet: todayNet,
            expectedFromYesterday: expectedFromYesterday,
            onSaveToday: () async {
              if (state.accounts.isEmpty) return;
              final result = await promptSaveBalance(
                context,
                accountsTotal: balance,
                monthNet: flow.monthAvailable,
                todayNet: todayNet,
                expectedFromYesterday: expectedFromYesterday,
              );
              if (result == null) return;
              state.saveBalanceSnapshot(note: result.note, total: result.total);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saldo guardado: ${moneyFull(result.total)}')),
                );
              }
            },
            onRestoreYesterday: () {
              final snap = state.yesterdaySnapshot();
              if (snap == null) return;
              state.restoreBalanceSnapshot(snap);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saldo restaurado: ${moneyFull(snap.total)}')),
              );
            },
          ),
          const SizedBox(height: 16),
          MonthFlowCard(
            income: flow.income,
            expenses: flow.expenses,
            net: flow.monthAvailable,
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
          AccountsBreakdown(
            accounts: state.accounts,
            transactions: state.transactions,
            year: now.year,
            month: now.month,
            onAddSuggested: () => state.addSuggestedAccounts(),
            onAddTemplate: (t) => _promptTemplateBalance(context, state, t),
          ),
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

  Future<void> _promptTemplateBalance(
    BuildContext context,
    AppState state,
    AccountTemplate template,
  ) async {
    final ctrl = TextEditingController(text: '0');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Agregar ${template.name}'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Saldo inicial (COP)',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Agregar')),
        ],
      ),
    );
    if (saved != true) return;
    final balance = double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
    state.addAccountFromTemplate(template, balance: balance);
  }
}
