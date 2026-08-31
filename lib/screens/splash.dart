import 'package:flutter/material.dart';

import '../core.dart';
import '../state.dart';
import 'shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _waitAndGo();
    }
  }

  Future<void> _waitAndGo() async {
    final state = Store.of(context);
    while (!state.loaded) {
      await Future.delayed(const Duration(milliseconds: 80));
      if (!mounted) return;
    }
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: T.budgetCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: T.volt.withOpacity(.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 26),
              const Text('Control',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1)),
              const SizedBox(height: 8),
              const Label('gastos · presupuesto · analiticas'),
            ],
          ),
        ),
      ),
    );
  }
}
