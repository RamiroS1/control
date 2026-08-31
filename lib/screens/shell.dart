import 'package:flutter/material.dart';

import '../core.dart';
import '../services.dart';
import '../state.dart';
import 'add_transaction.dart';
import 'analytics.dart';
import 'budget_detail.dart';
import 'home.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: _tab,
          children: [
            const HomeScreen(),
            const BudgetDetailScreen(),
            const AnalyticsScreen(),
            _ProfilePlaceholder(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          ),
          backgroundColor: T.volt,
          elevation: 8,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Colors.white.withOpacity(.92),
          elevation: 12,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavIcon(Icons.home_rounded, 0, _tab, (i) => setState(() => _tab = i)),
                _NavIcon(Icons.pie_chart_outline, 1, _tab, (i) => setState(() => _tab = i)),
                const SizedBox(width: 48),
                _NavIcon(Icons.show_chart, 2, _tab, (i) => setState(() => _tab = i)),
                _NavIcon(Icons.person_outline, 3, _tab, (i) => setState(() => _tab = i)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final int index;
  final int current;
  final ValueChanged<int> onTap;
  const _NavIcon(this.icon, this.index, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return IconButton(
      onPressed: () => onTap(index),
      icon: Icon(icon, color: active ? T.volt : T.ink45, size: 26),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const H1('Perfil'),
            const SizedBox(height: 20),
            Glass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Label('resumen'),
                  const SizedBox(height: 8),
                  Readout(moneyFull(Finance.workingBalance(state.accounts))),
                  const SizedBox(height: 4),
                  Text('Balance total en ${state.accounts.length} cuentas',
                      style: const TextStyle(color: T.ink45, fontSize: 13)),
                  const SizedBox(height: 16),
                  KV('Transacciones', '${state.transactions.length}'),
                  KV('Presupuesto mes', moneyFull(state.currentBudget().total)),
                  KV('Gastos mes', moneyFull(state.monthExpenses()),
                      color: T.clay),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
