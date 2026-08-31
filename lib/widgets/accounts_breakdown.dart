import 'package:flutter/material.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';

class AccountsBreakdown extends StatelessWidget {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final int year;
  final int month;
  final VoidCallback? onAddSuggested;
  final void Function(AccountTemplate template)? onAddTemplate;

  const AccountsBreakdown({
    super.key,
    required this.accounts,
    required this.transactions,
    required this.year,
    required this.month,
    this.onAddSuggested,
    this.onAddTemplate,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label('tus cuentas'),
          const SizedBox(height: 10),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agrega tus cuentas para ver cuanto tienes en cada una.',
                  style: TextStyle(color: T.ink45, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AccountTemplate.catalog.map((t) {
                    return _TemplateChip(
                      template: t,
                      onTap: onAddTemplate == null ? null : () => onAddTemplate!(t),
                    );
                  }).toList(),
                ),
                if (onAddSuggested != null) ...[
                  const SizedBox(height: 14),
                  Primary(
                    label: 'Crear las 4 cuentas',
                    height: 44,
                    onTap: onAddSuggested,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    final totalBalance = Finance.workingBalance(accounts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Label('tus cuentas'),
        const SizedBox(height: 10),
        ...accounts.map((account) {
          final income = Finance.accountIncome(transactions, account.id, year, month);
          final expenses =
              Finance.accountExpenses(transactions, account.id, year, month);
          final net = income - expenses;
          final share = totalBalance > 0 ? account.balance / totalBalance : 0.0;
          final icon = AccountTemplate.iconFor(account);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Glass(
              padding: const EdgeInsets.all(14),
              tint: account.color,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: account.color.withOpacity(.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: account.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(account.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(account.currency,
                                style: const TextStyle(fontSize: 11, color: T.ink45)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(moneyFull(account.balance),
                              style: const TextStyle(
                                  fontFamily: T.mono,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16)),
                          if (totalBalance > 0)
                            Text('${(share * 100).toStringAsFixed(0)}% del total',
                                style: const TextStyle(fontSize: 10, color: T.ink45)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Entradas',
                          value: moneyFull(income),
                          color: T.go,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Gastos',
                          value: moneyFull(expenses),
                          color: T.clay,
                        ),
                      ),
                      Expanded(
                        child: _MiniStat(
                          label: 'Neto mes',
                          value: moneyFull(net),
                          color: net >= 0 ? T.go : T.clay,
                        ),
                      ),
                    ],
                  ),
                  if (totalBalance > 0) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: share.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: T.hair,
                        valueColor: AlwaysStoppedAnimation(account.color),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (onAddTemplate != null) ...[
          const SizedBox(height: 4),
          _MissingTemplates(
            accounts: accounts,
            onAdd: onAddTemplate!,
          ),
        ],
      ],
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final AccountTemplate template;
  final VoidCallback? onTap;

  const _TemplateChip({required this.template, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: template.color.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: template.color.withOpacity(.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(template.icon, size: 16, color: template.color),
            const SizedBox(width: 6),
            Text(template.name,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12, color: template.color)),
          ],
        ),
      ),
    );
  }
}

class _MissingTemplates extends StatelessWidget {
  final List<Account> accounts;
  final void Function(AccountTemplate template) onAdd;

  const _MissingTemplates({required this.accounts, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final missing = AccountTemplate.catalog
        .where((t) => !accounts.any((a) => a.templateId == t.id))
        .toList();
    if (missing.isEmpty) return const SizedBox.shrink();

    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Agregar cuenta',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missing
                .map((t) => _TemplateChip(template: t, onTap: () => onAdd(t)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: T.ink45)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontFamily: T.mono,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: color)),
      ],
    );
  }
}
