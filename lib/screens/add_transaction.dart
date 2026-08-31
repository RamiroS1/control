import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';
import '../models.dart';
import '../state.dart';

class AddTransactionScreen extends StatefulWidget {
  /// 0 = entrada, 1 = gasto
  final int initialTab;

  const AddTransactionScreen({super.key, this.initialTab = 0});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _noteCtrl = TextEditingController(text: 'Diario');
  final _amountCtrl = TextEditingController();
  late TabController _tabs;
  String _categoryId = CategoryDef.ingresos.id;
  String _accountId = '';
  DateTime _date = DateTime.now();
  bool _accountInit = false;

  TxType get _type => _tabs.index == 0 ? TxType.income : TxType.expense;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
    _tabs.addListener(_onTabChanged);
  }

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

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    setState(() {
      if (_type == TxType.income) {
        _categoryId = CategoryDef.ingresos.id;
        if (_noteCtrl.text.trim().isEmpty) _noteCtrl.text = 'Diario';
      } else {
        if (CategoryDef.byId(_categoryId).incomeOnly) {
          _categoryId = CategoryDef.comida.id;
        }
        if (_noteCtrl.text == 'Diario') _noteCtrl.text = '';
      }
    });
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    _noteCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _save() {
    if (_accountId.isEmpty) {
      _toast('Primero agrega una cuenta en Perfil');
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.').trim());
    if (amount == null || amount <= 0) {
      _toast('Ingresa un monto valido');
      return;
    }

    final type = _type;
    final cats = CategoryDef.forType(type);
    var categoryId = _categoryId;
    if (!cats.any((c) => c.id == categoryId)) {
      categoryId = cats.first.id;
    }

    final note = _noteCtrl.text.trim();
    final state = Store.of(context);

    try {
      state.addTransaction(Transaction(
        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        accountId: _accountId,
        categoryId: categoryId,
        type: type,
        amount: amount,
        date: DateTime(_date.year, _date.month, _date.day),
        note: note.isEmpty ? null : note,
      ));
      Navigator.of(context).pop();
    } catch (_) {
      _toast('No se pudo guardar. Revisa la cuenta seleccionada.');
    }
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
    final incomeCats = CategoryDef.forType(TxType.income);
    final expenseCats = CategoryDef.forType(TxType.expense);
    final activeCats = _type == TxType.income ? incomeCats : expenseCats;

    if (!activeCats.any((c) => c.id == _categoryId)) {
      _categoryId = activeCats.first.id;
    }

    return Ambient(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Registrar movimiento',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
          bottom: TabBar(
            controller: _tabs,
            labelColor: T.ink,
            unselectedLabelColor: T.ink45,
            indicatorColor: T.volt,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            tabs: const [
              Tab(text: 'Entrada'),
              Tab(text: 'Gasto'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: [
            _FormBody(
              isIncome: true,
              state: state,
              noteCtrl: _noteCtrl,
              amountCtrl: _amountCtrl,
              categoryId: _categoryId,
              accountId: _accountId,
              dateLabel: _dateLabel(),
              categories: incomeCats,
              onCategoryChanged: (id) => setState(() => _categoryId = id),
              onAccountChanged: (id) => setState(() => _accountId = id),
              onPickDate: _pickDate,
              onSave: _save,
            ),
            _FormBody(
              isIncome: false,
              state: state,
              noteCtrl: _noteCtrl,
              amountCtrl: _amountCtrl,
              categoryId: _categoryId,
              accountId: _accountId,
              dateLabel: _dateLabel(),
              categories: expenseCats,
              onCategoryChanged: (id) => setState(() => _categoryId = id),
              onAccountChanged: (id) => setState(() => _accountId = id),
              onPickDate: _pickDate,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  final bool isIncome;
  final AppState state;
  final TextEditingController noteCtrl;
  final TextEditingController amountCtrl;
  final String categoryId;
  final String accountId;
  final String dateLabel;
  final List<CategoryDef> categories;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onAccountChanged;
  final VoidCallback onPickDate;
  final VoidCallback onSave;

  const _FormBody({
    required this.isIncome,
    required this.state,
    required this.noteCtrl,
    required this.amountCtrl,
    required this.categoryId,
    required this.accountId,
    required this.dateLabel,
    required this.categories,
    required this.onCategoryChanged,
    required this.onAccountChanged,
    required this.onPickDate,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (state.accounts.isEmpty)
          Glass(
            child: Text(
              'Ve a Perfil y crea una cuenta antes de registrar ${isIncome ? 'entradas' : 'gastos'}.',
              style: const TextStyle(color: T.clay, fontSize: 13, height: 1.4),
            ),
          )
        else ...[
          Label(isIncome ? 'descripcion ingreso' : 'descripcion'),
          const SizedBox(height: 8),
          Glass(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: isIncome ? 'Diario' : 'Ej. Almuerzo, Uber...',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Label('cuenta'),
          const SizedBox(height: 8),
          _AccountDropdown(
            accounts: state.accounts,
            accountId: accountId,
            onChanged: onAccountChanged,
          ),
          const SizedBox(height: 16),
          const Label('categoria'),
          const SizedBox(height: 8),
          _CategoryDropdown(
            categories: categories,
            categoryId: categoryId,
            onChanged: onCategoryChanged,
          ),
          const SizedBox(height: 16),
          const Label('fecha'),
          const SizedBox(height: 8),
          Glass(
            onTap: onPickDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: T.volt),
                const SizedBox(width: 10),
                Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              style: const TextStyle(
                fontFamily: T.mono,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
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
            onTap: onSave,
          ),
        ],
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<CategoryDef> categories;
  final String categoryId;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.categoryId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeCategoryId = categories.any((c) => c.id == categoryId)
        ? categoryId
        : categories.first.id;

    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: safeCategoryId,
          icon: const Icon(Icons.expand_more, color: T.ink45),
          items: categories.map((c) {
            return DropdownMenuItem(
              value: c.id,
              child: Row(
                children: [
                  Icon(c.icon, color: c.color, size: 20),
                  const SizedBox(width: 10),
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  final List<Account> accounts;
  final String accountId;
  final ValueChanged<String> onChanged;

  const _AccountDropdown({
    required this.accounts,
    required this.accountId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = accounts.any((a) => a.id == accountId)
        ? accountId
        : accounts.first.id;

    return Glass(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.expand_more, color: T.ink45),
          items: accounts.map((a) {
            return DropdownMenuItem(
              value: a.id,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: a.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Text(
                    moneyFull(a.balance),
                    style: const TextStyle(fontFamily: T.mono, fontSize: 11, color: T.ink45),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
