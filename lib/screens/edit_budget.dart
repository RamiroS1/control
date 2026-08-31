import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';
import '../models.dart';
import '../state.dart';

class EditBudgetScreen extends StatefulWidget {
  const EditBudgetScreen({super.key});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  final _totalCtrl = TextEditingController();
  final _byCat = <String, TextEditingController>{};
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = Store.of(context);
    final plan = state.currentBudget();
    _totalCtrl.text = plan.total.toStringAsFixed(0);

    final catIds = plan.byCategory.keys.isNotEmpty
        ? plan.byCategory.keys.toList()
        : CategoryDef.expenseCatalog.map((c) => c.id).toList();

    for (final id in catIds) {
      final amount = plan.byCategory[id] ?? 0;
      _byCat[id] = TextEditingController(
        text: amount > 0 ? amount.toStringAsFixed(0) : '',
      );
    }
  }

  @override
  void dispose() {
    _totalCtrl.dispose();
    for (final c in _byCat.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final state = Store.of(context);
    final focus = state.focusMonth;
    final byCategory = <String, double>{};
    for (final e in _byCat.entries) {
      final v = double.tryParse(e.value.text.replaceAll(',', '.'));
      if (v != null && v > 0) byCategory[e.key] = v;
    }
    final total = double.tryParse(_totalCtrl.text.replaceAll(',', '.')) ?? 0;
    state.updateBudget(BudgetPlan(
      year: focus.year,
      month: focus.month,
      total: total,
      byCategory: byCategory,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final focus = state.focusMonth;

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Presupuesto ${_monthName(focus.month)} ${focus.year}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Label('total mensual'),
            const SizedBox(height: 8),
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _totalCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                style: const TextStyle(fontFamily: T.mono, fontSize: 22, fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixText: '\$ ',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Si defines montos por categoria, se usan esos. Si no, se usa el total.',
              style: TextStyle(fontSize: 12, color: T.ink45),
            ),
            const SizedBox(height: 24),
            const Label('por categoria'),
            const SizedBox(height: 10),
            ..._byCat.entries.map((e) {
              final cat = CategoryDef.byId(e.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Glass(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      Icon(cat.icon, color: cat.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: e.value,
                          textAlign: TextAlign.right,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                          style: const TextStyle(fontFamily: T.mono, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: '0',
                            prefixText: '\$ ',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            Primary(label: 'Guardar presupuesto', onTap: _save),
          ],
        ),
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
