import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<Expense> getExpensesForDay(DateTime day) {
    final box = Hive.box<Expense>('expenses');
    return box.values
        .where((e) =>
    e.date.year == day.year &&
        e.date.month == day.month &&
        e.date.day == day.day)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final expenses = getExpensesForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View'),
      ),
      body: Column(
        children: [
          TableCalendar(
            focusedDay: _focusedDay,
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
          ),
          const SizedBox(height: 10),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('No expenses on this day.'))
                : ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (context, index) {
                final e = expenses[index];
                return ListTile(
                  leading: const Icon(Icons.money),
                  title: Text(e.category),
                  subtitle: Text(DateFormat('yyyy-MM-dd').format(e.date)),
                  trailing: Text('₹${e.amount.toStringAsFixed(2)}'),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
