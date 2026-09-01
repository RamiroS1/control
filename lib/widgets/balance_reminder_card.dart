import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';

class BalanceReminderCard extends StatelessWidget {
  final List<BalanceSnapshot> snapshots;
  final List<Account> accounts;
  final double currentTotal;
  final double monthNet;
  final double todayNet;
  final double? expectedFromYesterday;
  final VoidCallback onSaveToday;
  final VoidCallback? onRestoreYesterday;

  const BalanceReminderCard({
    super.key,
    required this.snapshots,
    required this.accounts,
    required this.currentTotal,
    required this.monthNet,
    required this.todayNet,
    this.expectedFromYesterday,
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
                'En cuentas tienes ${moneyFull(currentTotal)} '
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
              'Al final del dia guarda cuanto te queda en total (todas tus cuentas). '
              'No es lo mismo que el neto del mes.',
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

class SaveBalanceResult {
  final double total;
  final String? note;

  const SaveBalanceResult({required this.total, this.note});
}

Future<SaveBalanceResult?> promptSaveBalance(
  BuildContext context, {
  required double accountsTotal,
  required double monthNet,
  required double todayNet,
  required double? expectedFromYesterday,
}) {
  final defaultTotal = _suggestedSaveTotal(
    accountsTotal: accountsTotal,
    monthNet: monthNet,
    expectedFromYesterday: expectedFromYesterday,
  );

  return showDialog<SaveBalanceResult>(
    context: context,
    builder: (ctx) => _SaveBalanceDialog(
      initialTotal: defaultTotal,
      accountsTotal: accountsTotal,
      monthNet: monthNet,
      todayNet: todayNet,
      expectedFromYesterday: expectedFromYesterday,
    ),
  );
}

double _suggestedSaveTotal({
  required double accountsTotal,
  required double monthNet,
  required double? expectedFromYesterday,
}) {
  if (expectedFromYesterday != null) {
    return expectedFromYesterday;
  }
  final accountsDiffersFromMonth =
      (accountsTotal - monthNet).abs() > 0.01 && accountsTotal > monthNet;
  if (accountsDiffersFromMonth) {
    return monthNet;
  }
  return accountsTotal;
}

class _SaveBalanceDialog extends StatefulWidget {
  final double initialTotal;
  final double accountsTotal;
  final double monthNet;
  final double todayNet;
  final double? expectedFromYesterday;

  const _SaveBalanceDialog({
    required this.initialTotal,
    required this.accountsTotal,
    required this.monthNet,
    required this.todayNet,
    required this.expectedFromYesterday,
  });

  @override
  State<_SaveBalanceDialog> createState() => _SaveBalanceDialogState();
}

class _SaveBalanceDialogState extends State<_SaveBalanceDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: _formatAmount(widget.initialTotal));
    _noteCtrl = TextEditingController(text: 'Me quedaron ${moneyFull(widget.initialTotal)}');
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatAmount(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(2);
  }

  double? _parseAmount() {
    final raw = _amountCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(raw);
  }

  bool get _accountsMismatch {
    final amount = _parseAmount();
    if (amount == null) return false;
    return (amount - widget.accountsTotal).abs() > 0.01;
  }

  bool get _expectedMismatch {
    final amount = _parseAmount();
    if (amount == null || widget.expectedFromYesterday == null) return false;
    return (amount - widget.expectedFromYesterday!).abs() > 0.01;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Guardar saldo del dia'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cuenta cuanto te queda en total (efectivo, Nequi, banco, etc.). '
              'El neto del mes solo refleja entradas menos gastos de este mes.',
              style: TextStyle(fontSize: 12, color: T.ink45, height: 1.35),
            ),
            const SizedBox(height: 14),
            _ContextRow(label: 'Suma de tus cuentas', value: moneyFull(widget.accountsTotal)),
            _ContextRow(label: 'Neto del mes', value: moneyFull(widget.monthNet)),
            _ContextRow(label: 'Neto de hoy', value: moneyFull(widget.todayNet)),
            if (widget.expectedFromYesterday != null)
              _ContextRow(
                label: 'Ayer + movimientos de hoy',
                value: moneyFull(widget.expectedFromYesterday!),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cuanto te queda en total',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nota / recordatorio',
                border: OutlineInputBorder(),
              ),
            ),
            if (_accountsMismatch) ...[
              const SizedBox(height: 12),
              const Text(
                'Este monto no coincide con la suma de tus cuentas. '
                'Al guardar, ajustaremos los saldos de las cuentas para que coincidan.',
                style: TextStyle(fontSize: 12, color: T.clay, height: 1.35),
              ),
            ],
            if (_expectedMismatch && widget.expectedFromYesterday != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Difiere de ayer + movimientos de hoy. '
                'Revisa si registraste una entrada que ya tenias.',
                style: TextStyle(fontSize: 12, color: T.clay, height: 1.35),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final amount = _parseAmount();
            if (amount == null || amount < 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ingresa un monto valido')),
              );
              return;
            }
            Navigator.pop(
              ctx,
              SaveBalanceResult(
                total: amount,
                note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _ContextRow extends StatelessWidget {
  final String label;
  final String value;

  const _ContextRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: T.ink45)),
          ),
          Text(value,
              style: const TextStyle(
                  fontFamily: T.mono, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}
