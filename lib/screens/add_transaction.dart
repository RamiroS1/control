import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';
import '../models.dart';
import '../state.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _noteCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TxType _type = TxType.expense;
  String _categoryId = CategoryDef.comida.id;
  String _accountId = '';
  DateTime _date = DateTime.now();
  bool _accountInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_accountInit) {
      _accountInit = true;
      final state = Store.of(context);
      if (state.accounts.isNotEmpty) {
        _accountId = state.accounts.first.id;
      }
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0 || _accountId.isEmpty) return;
    final state = Store.of(context);
    state.addTransaction(Transaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      accountId: _accountId,
      categoryId: _categoryId,
      type: _type,
      amount: amount,
      date: DateTime(_date.year, _date.month, _date.day),
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String _dateLabel() {
    final now = DateTime.now();
    if (_date.year == now.year && _date.month == now.month && _date.day == now.day) {
      return 'Hoy';
    }
    const months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${_date.day} ${months[_date.month - 1]} ${_date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final cats = CategoryDef.forType(_type);
    final isIncome = _type == TxType.income;

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            isIncome ? 'Registrar entrada' : 'Registrar gasto',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Icon(Icons.account_balance_wallet,
                  size: 64, color: T.volt.withOpacity(.35)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Gasto',
                    selected: _type == TxType.expense,
                    color: T.clay,
                    onTap: () => setState(() {
                      _type = TxType.expense;
                      if (CategoryDef.byId(_categoryId).incomeOnly) {
                        _categoryId = CategoryDef.comida.id;
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeChip(
                    label: 'Entrada',
                    selected: _type == TxType.income,
                    color: T.go,
                    onTap: () => setState(() {
                      _type = TxType.income;
                      _categoryId = CategoryDef.ingresos.id;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Label('nombre'),
            const SizedBox(height: 8),
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Descripcion',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Label('cuenta'),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.accounts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final a = state.accounts[i];
                  final sel = a.id == _accountId;
                  return GestureDetector(
                    onTap: () => setState(() => _accountId = a.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: sel ? a.color.withOpacity(.25) : Colors.white.withOpacity(.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: sel ? a.color : T.edge, width: sel ? 2 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(a.name,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: sel ? a.color : T.ink45)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Label('categoria'),
            const SizedBox(height: 8),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final c = cats[i];
                  final sel = c.id == _categoryId;
                  return GestureDetector(
                    onTap: () => setState(() => _categoryId = c.id),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: sel ? c.color.withOpacity(.25) : Colors.white.withOpacity(.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: sel ? c.color : T.edge, width: sel ? 2 : 1),
                      ),
                      child: Icon(c.icon, color: c.color, size: 24),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Label('fecha'),
            const SizedBox(height: 8),
            Glass(
              onTap: _pickDate,
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: T.volt),
                  const SizedBox(width: 10),
                  Text(_dateLabel(), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: T.ink45, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Label('importe'),
            const SizedBox(height: 8),
            Glass(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                style: const TextStyle(
                    fontFamily: T.mono,
                    fontSize: 24,
                    fontWeight: FontWeight.w700),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  prefixText: '\$ ',
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Primary(
              label: isIncome ? 'Guardar entrada' : 'Guardar gasto',
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.18) : Colors.white.withOpacity(.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? color : T.edge, width: selected ? 2 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? color : T.ink45)),
      ),
    );
  }
}
