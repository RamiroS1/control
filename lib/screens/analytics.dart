import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core.dart';
import '../models.dart';
import '../services.dart';
import '../state.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _range = 1; // 0=3m, 1=6m, 2=12m

  @override
  Widget build(BuildContext context) {
    final state = Store.of(context);
    final now = DateTime.now();
    final counts = [3, 6, 12];
    final count = counts[_range];
    final totals = Finance.monthlyTotals(state.transactions, now, count);
    final labels = Finance.monthLabels(now, count);
    final balance = Finance.workingBalance(state.accounts);
    final byCat = Finance.byCategory(
        state.transactions, state.focusMonth.year, state.focusMonth.month);
    final maxBar = totals.isEmpty ? 1 : totals.reduce((a, b) => a > b ? a : b);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          const H1('Analiticas'),
          const SizedBox(height: 16),
          _RangePicker(
            labels: ['3M', '6M', '12M'],
            selected: _range,
            onSelect: (i) => setState(() => _range = i),
          ),
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Label('balance operativo'),
                const SizedBox(height: 6),
                Readout(moneyFull(balance)),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(labels[i],
                                    style: const TextStyle(
                                        fontSize: 10, color: T.ink45)),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                              totals.length, (i) => FlSpot(i.toDouble(), totals[i])),
                          isCurved: true,
                          color: T.volt,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                              radius: 4,
                              color: T.volt,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: T.volt.withOpacity(.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Label('gastos por mes'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxBar * 1.2,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i < 0 || i >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(labels[i],
                                  style:
                                      const TextStyle(fontSize: 9, color: T.ink45));
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(totals.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: totals[i],
                              width: 14,
                              borderRadius: BorderRadius.circular(6),
                              gradient: T.gradient,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Label('por categoria'),
                const SizedBox(height: 12),
                if (byCat.isEmpty)
                  const Text('Sin gastos este mes',
                      style: TextStyle(color: T.ink45))
                else
                  SizedBox(
                    height: 160,
                    child: Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 36,
                              sections: _pieSections(byCat),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: byCat.entries.take(5).map((e) {
                              final cat = CategoryDef.byId(e.key);
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: cat.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(cat.name,
                                          style: const TextStyle(fontSize: 11)),
                                    ),
                                    Text(moneyFull(e.value),
                                        style: const TextStyle(
                                            fontFamily: T.mono,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _pieSections(Map<String, double> byCat) {
    final total = byCat.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return [];
    return byCat.entries.map((e) {
      final cat = CategoryDef.byId(e.key);
      final pct = e.value / total * 100;
      return PieChartSectionData(
        value: e.value,
        title: '${pct.toStringAsFixed(0)}%',
        color: cat.color,
        radius: 42,
        titleStyle: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
      );
    }).toList();
  }
}

class _RangePicker extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  const _RangePicker({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: active ? T.gradient : null,
                color: active ? null : Colors.white.withOpacity(.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? Colors.transparent : T.edge),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: active ? Colors.white : T.ink45,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
