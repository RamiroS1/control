import 'package:flutter/material.dart';

import '../core.dart';

class BudgetCard extends StatelessWidget {
  final String label;
  final String month;
  final double remaining;
  final double total;
  final int daysLeft;
  final double daily;

  const BudgetCard({
    super.key,
    required this.label,
    required this.month,
    required this.remaining,
    required this.total,
    required this.daysLeft,
    required this.daily,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (total - remaining) / total : 0;
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withOpacity(.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(month,
                    style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DISPONIBLE',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.7),
                          fontSize: 10,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(moneyFull(remaining),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('DE ${moneyFull(total)}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.7), fontSize: 11)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$daysLeft dias restantes · ${moneyFull(daily)}/dia',
              style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
