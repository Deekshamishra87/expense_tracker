import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class ExpensePieChart extends StatefulWidget {
  final List<Expense> expenses;

  const ExpensePieChart({super.key, required this.expenses});

  @override
  State<ExpensePieChart> createState() => _ExpensePieChartState();
}

class _ExpensePieChartState extends State<ExpensePieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = {};

    for (var e in widget.expenses) {
      categoryTotals.update(
        e.category,
            (val) => val + e.amount,
        ifAbsent: () => e.amount,
      );
    }

    var entries = categoryTotals.entries.toList();

    // Top 5 + Others logic
    if (entries.length > 6) {
      entries.sort((a, b) => b.value.compareTo(a.value));
      final top5 = entries.take(5).toList();
      final restTotal = entries.skip(5).fold(0.0, (sum, e) => sum + e.value);
      top5.add(MapEntry('Others', restTotal));
      entries = top5;
    }

    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.pink,
      Colors.green,
      Colors.deepPurple,
      Colors.brown,
    ];

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No data for chart'),
      );
    }

    final chartSections = List.generate(entries.length, (i) {
      final entry = entries[i];
      final isTouched = i == touchedIndex;

      return PieChartSectionData(
        value: entry.value,
        color: colors[i % colors.length],
        radius: isTouched ? 75 : 60,
        showTitle: isTouched,
        title: isTouched ? '₹${entry.value.toStringAsFixed(0)}' : '',
        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    });

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(scale: value, child: child),
              );
            },
            child: PieChart(
              PieChartData(
                sections: chartSections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      touchedIndex =
                          response?.touchedSection?.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // 🔽 Clean legend below
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: List.generate(entries.length, (i) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entries[i].key,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
