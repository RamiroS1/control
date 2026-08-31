import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';
import '../widgets/budget_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final now = state.focusMonth;
    final spent = state.monthExpenses();
    final plan = state.currentBudget();
    final total = Finance.totalBudgeted(plan);
    final remaining = total - spent;
    final prevMonth = DateTime(now.year, now.month - 1);
    final prevSpent = Finance.expenses(
        state.transactions, prevMonth.year, prevMonth.month);
    final pct = Finance.pctChange(spent, prevSpent);
    final recent = state.transactions.take(5).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          Row(
            children: [
              const Expanded(child: H1('Inicio')),
              IconButton(
                icon: const Icon(Icons.search, color: T.ink45),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Label('cuentas'),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.accounts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _AccountCard(account: state.accounts[i]),
            ),
          ),
          const SizedBox(height: 20),
          BudgetCard(
            label: 'Mi presupuesto ${now.year}',
            month: _monthName(now.month),
            remaining: remaining,
            total: total,
            daysLeft: Finance.daysRemaining(DateTime.now()),
            daily: Finance.dailyAllowance(remaining, Finance.daysRemaining(DateTime.now())),
          ),
          const SizedBox(height: 16),
          Glass(
            child: Row(
              children: [
                Icon(Icons.trending_up, color: pct >= 0 ? T.clay : T.go, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}% vs mes anterior',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        'Gastaste ${moneyFull(spent)} este mes',
                        style: const TextStyle(color: T.ink45, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(moneyFull(spent),
                    style: TextStyle(
                        fontFamily: T.mono,
                        fontWeight: FontWeight.w700,
                        color: T.clay)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Label('movimientos recientes'),
          const SizedBox(height: 10),
          ...recent.map((t) => _TxRow(tx: t)),
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

class _AccountCard extends StatelessWidget {
  final Account account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Glass(
      tint: account.color,
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(account.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Readout(moneyFull(account.balance), size: 22),
            Text(account.currency,
                style: const TextStyle(fontSize: 11, color: T.ink45)),
          ],
        ),
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final cat = CategoryDef.byId(tx.categoryId);
    final isExp = tx.type == TxType.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cat.color.withOpacity(.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(cat.icon, color: cat.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (tx.note != null)
                    Text(tx.note!, style: const TextStyle(fontSize: 11, color: T.ink45)),
                ],
              ),
            ),
            Text(
              '${isExp ? '-' : '+'}${moneyFull(tx.amount)}',
              style: TextStyle(
                fontFamily: T.mono,
                fontWeight: FontWeight.w700,
                color: isExp ? T.clay : T.go,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
