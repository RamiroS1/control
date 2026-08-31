import 'package:flutter/material.dart';

import '../core.dart';
import 'add_transaction.dart';
import 'analytics.dart';
import 'budget_detail.dart';
import 'home.dart';
import 'profile.dart';

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
            const ProfileScreen(),
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
