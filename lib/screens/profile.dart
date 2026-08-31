import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
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
                Text(
                  state.accounts.isEmpty
                      ? 'Sin cuentas — agrega la primera abajo'
                      : 'Balance total en ${state.accounts.length} cuentas',
                  style: const TextStyle(color: T.ink45, fontSize: 13),
                ),
                const SizedBox(height: 16),
                KV('Transacciones', '${state.transactions.length}'),
                KV('Presupuesto mes', moneyFull(state.currentBudget().total)),
                KV('Gastos mes', moneyFull(state.monthExpenses()), color: T.clay),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Label('cuentas'),
          const SizedBox(height: 10),
          if (state.accounts.isEmpty)
            const Glass(
              child: Text(
                'Aun no tienes cuentas. Crea una con tu saldo real.',
                style: TextStyle(color: T.ink45, fontSize: 13),
              ),
            )
          else
            ...state.accounts.map(
              (a) => _AccountRow(
                account: a,
                onEdit: () => _showAccountDialog(context, state, existing: a),
              ),
            ),
          const SizedBox(height: 10),
          Glass(
            onTap: () => _showAccountDialog(context, state),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: T.volt, size: 20),
                SizedBox(width: 8),
                Text('Agregar cuenta', style: TextStyle(fontWeight: FontWeight.w700, color: T.volt)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Label('datos'),
          const SizedBox(height: 10),
          Glass(
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.upload_file,
                  title: 'Exportar backup',
                  subtitle: 'Copia JSON al portapapeles',
                  onTap: () => _export(context, state),
                ),
                const Divider(height: 1),
                _ActionRow(
                  icon: Icons.download,
                  title: 'Importar backup',
                  subtitle: 'Pega JSON exportado antes',
                  onTap: () => _import(context, state),
                ),
                const Divider(height: 1),
                _ActionRow(
                  icon: Icons.science_outlined,
                  title: 'Cargar datos demo',
                  subtitle: 'Ejemplo para probar la app',
                  onTap: () => _confirm(
                    context,
                    title: 'Cargar demo',
                    body: 'Se reemplazaran tus cuentas, movimientos y presupuestos.',
                    onConfirm: () => state.loadDemoData(),
                  ),
                ),
                const Divider(height: 1),
                _ActionRow(
                  icon: Icons.delete_outline,
                  title: 'Borrar todo',
                  subtitle: 'Empezar de cero con datos reales',
                  color: T.clay,
                  onTap: () => _confirm(
                    context,
                    title: 'Borrar todos los datos',
                    body: 'Esta accion no se puede deshacer.',
                    destructive: true,
                    onConfirm: () => state.clearAll(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, AppState state) async {
    final json = state.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup copiado al portapapeles')),
      );
    }
  }

  Future<void> _import(BuildContext context, AppState state) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar backup'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: ctrl,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Pega aqui el JSON exportado',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Importar')),
        ],
      ),
    );
    if (ok != true || ctrl.text.trim().isEmpty) return;
    try {
      await state.importJson(ctrl.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos importados correctamente')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('JSON invalido — revisa el formato')),
        );
      }
    }
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required VoidCallback onConfirm,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: T.clay) : null,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(destructive ? 'Borrar' : 'Confirmar'),
          ),
        ],
      ),
    );
    if (ok == true) onConfirm();
  }

  Future<void> _showAccountDialog(
    BuildContext context,
    AppState state, {
    Account? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final balanceCtrl = TextEditingController(
      text: existing != null ? existing.balance.toStringAsFixed(2) : '',
    );
    final currencyCtrl = TextEditingController(text: existing?.currency ?? 'USD');
    var color = existing?.color ?? T.volt;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nueva cuenta' : 'Editar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Saldo inicial'),
              ),
              TextField(
                controller: currencyCtrl,
                decoration: const InputDecoration(labelText: 'Moneda'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [T.volt, T.sun, T.iris, T.go, T.clay, T.mint].map((c) {
                  final sel = color.value == c.value;
                  return GestureDetector(
                    onTap: () => setLocal(() => color = c),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(color: sel ? T.ink : Colors.transparent, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final name = nameCtrl.text.trim();
    final balance = double.tryParse(balanceCtrl.text.replaceAll(',', '.'));
    if (name.isEmpty || balance == null) return;

    if (existing != null) {
      state.updateAccount(Account(
        id: existing.id,
        name: name,
        currency: currencyCtrl.text.trim().isEmpty ? 'USD' : currencyCtrl.text.trim(),
        balance: balance,
        color: color,
      ));
    } else {
      state.addAccount(Account(
        id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        currency: currencyCtrl.text.trim().isEmpty ? 'USD' : currencyCtrl.text.trim(),
        balance: balance,
        color: color,
      ));
    }
  }
}

class _AccountRow extends StatelessWidget {
  final Account account;
  final VoidCallback onEdit;
  const _AccountRow({required this.account, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Glass(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 40,
              decoration: BoxDecoration(
                color: account.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(account.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(account.currency, style: const TextStyle(fontSize: 11, color: T.ink45)),
                ],
              ),
            ),
            Text(
              moneyFull(account.balance),
              style: const TextStyle(fontFamily: T.mono, fontWeight: FontWeight.w700),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: T.ink45),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? T.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: c)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: T.ink45)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: T.ink45, size: 20),
          ],
        ),
      ),
    );
  }
}
