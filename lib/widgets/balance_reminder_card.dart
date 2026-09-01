import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';

class BalanceReminderCard extends StatelessWidget {
  final List<BalanceSnapshot> snapshots;
  final List<Account> accounts;
  final double currentTotal;
  final VoidCallback onSaveToday;
  final VoidCallback? onRestoreYesterday;

  const BalanceReminderCard({
    super.key,
    required this.snapshots,
    required this.accounts,
    required this.currentTotal,
    required this.onSaveToday,
    this.onRestoreYesterday,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todaySnap = Finance.snapshotForDay(snapshots, todayStart);
    final yesterdaySnap = Finance.latestSnapshotBefore(snapshots, todayStart);

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: T.iris.withOpacity(.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Saldo guardado',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: T.iris)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (todaySnap != null) ...[
            Text('Hoy guardaste ${moneyFull(todaySnap.total)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            if (todaySnap.note != null && todaySnap.note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(todaySnap.note!,
                    style: const TextStyle(fontSize: 12, color: T.ink45)),
              ),
          ] else if (yesterdaySnap != null) ...[
            Text(
              'Ayer te quedaron ${moneyFull(yesterdaySnap.total)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ese dinero ya es tuyo — no lo vuelvas a registrar como entrada nueva. '
              'Usa "Saldo que ya tenia" o restaura el saldo de ayer.',
              style: TextStyle(fontSize: 12, color: T.ink45, height: 1.4),
            ),
            if ((currentTotal - yesterdaySnap.total).abs() > 0.01) ...[
              const SizedBox(height: 8),
              Text(
                'Ahora tienes ${moneyFull(currentTotal)} registrado '
                '(${currentTotal > yesterdaySnap.total ? 'mas' : 'menos'} que ayer).',
                style: TextStyle(
                  fontSize: 12,
                  color: currentTotal > yesterdaySnap.total ? T.clay : T.go,
                  height: 1.35,
                ),
              ),
            ],
          ] else
            const Text(
              'Al final del dia guarda cuanto te queda. Asi manana sabras '
              'que no debes volver a anotarlo como ingreso.',
              style: TextStyle(fontSize: 13, color: T.ink45, height: 1.4),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Primary(
                  label: todaySnap == null ? 'Guardar saldo de hoy' : 'Actualizar saldo de hoy',
                  height: 44,
                  onTap: onSaveToday,
                ),
              ),
            ],
          ),
          if (yesterdaySnap != null && onRestoreYesterday != null) ...[
            const SizedBox(height: 8),
            Glass(
              onTap: onRestoreYesterday,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 18, color: T.volt),
                  SizedBox(width: 8),
                  Text('Restaurar saldo de ayer',
                      style: TextStyle(fontWeight: FontWeight.w700, color: T.volt)),
                ],
              ),
            ),
          ],
          if (snapshots.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Label('ultimos guardados'),
            const SizedBox(height: 8),
            ...snapshots.take(3).map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Text(_dayLabel(s.date),
                          style: const TextStyle(fontSize: 11, color: T.ink45)),
                      const Spacer(),
                      Text(moneyFull(s.total),
                          style: const TextStyle(
                              fontFamily: T.mono, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Hoy';
    if (day == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${d.day}/${d.month}/${d.year}';
  }
}

Future<String?> promptBalanceNote(BuildContext context, double total) {
  final ctrl = TextEditingController(text: 'Me quedaron ${moneyFull(total)}');
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Guardar saldo del dia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total: ${moneyFull(total)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Nota / recordatorio',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
