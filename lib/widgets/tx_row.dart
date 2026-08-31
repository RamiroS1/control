import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';

class TxRow extends StatelessWidget {
  final Transaction tx;
  const TxRow({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final cat = CategoryDef.byId(tx.categoryId);
    final isExp = tx.type == TxType.expense;
    final dateLabel = _formatDate(tx.date);

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
                  Text(
                    [
                      if (tx.note != null && tx.note!.isNotEmpty) tx.note!,
                      dateLabel,
                      isExp ? 'Gasto' : 'Entrada',
                    ].join(' · '),
                    style: const TextStyle(fontSize: 11, color: T.ink45),
                  ),
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

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Hoy';
    }
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}
