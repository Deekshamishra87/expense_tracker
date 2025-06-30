import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/widgets/expense_pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:expense_tracker/services/ai_service.dart';

import '../models/expense_model.dart';
import 'calendar_screen.dart';

enum FilterType { oneDay, oneWeek, oneMonth, all }

final Map<String, String> categoryIcons = {
  'Food': 'assets/images/food.png',
  'Travel': 'assets/images/travel.png',
  'Shopping': 'assets/images/shopping.png',
  'Rent': 'assets/images/rent.png',
  'Bills': 'assets/images/bills.png',
  'Entertainment': 'assets/images/entertainment.png',
  'Work': 'assets/images/work.png',
  'Other': 'assets/images/others.png',
};

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  const DashboardScreen({super.key, this.onToggleTheme});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  FilterType selectedFilter = FilterType.all;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();

  String _searchQuery = '';
  double expenseLimit = 5000;
  bool hasShownLimitWarning = false;
  final player = AudioPlayer();

  String aiText = '';
  bool isLoadingAI = false;
  String customPromptResult = '';

  Future<void> fetchAI(double spent, int daysLeft) async {
    setState(() {
      isLoadingAI = true;
      aiText = '';
    });

    try {
      String prompt = "I have ₹$spent left and $daysLeft days to go. Suggest a smart way to manage my money.";
      String suggestion = await GeminiBridgeService.getSuggestion(prompt);
      setState(() {
        aiText = suggestion;
      });
    } catch (e) {
      print('AI fetch error: $e');
      setState(() {
        aiText = '⚠️ Failed to fetch AI suggestion.';
      });
    } finally {
      setState(() {
        isLoadingAI = false;
      });
    }
  }

  void updateFilter(FilterType type) {
    setState(() => selectedFilter = type);
  }

  List<Expense> applyFilter(List<Expense> all) {
    final now = DateTime.now();
    List<Expense> filtered = switch (selectedFilter) {
      FilterType.oneDay => all.where((e) =>
      e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day).toList(),
      FilterType.oneWeek => all.where((e) =>
      now.difference(e.date).inDays < 7).toList(),
      FilterType.oneMonth => all.where((e) =>
      e.date.year == now.year && e.date.month == now.month).toList(),
      _ => all,
    };

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) =>
          e.category.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return filtered;
  }

  void showLimitDialog() {
    final controller = TextEditingController(text: expenseLimit.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Expense Limit'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Limit in ₹'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => expenseLimit = 5000);
              Navigator.pop(context);
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              final entered = double.tryParse(controller.text.trim());
              if (entered != null && entered > 0) {
                setState(() => expenseLimit = entered);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void playLimitSound() async {
    try {
      await player.play(AssetSource('sounds/audio.mp3'));
    } catch (e) {
      debugPrint('Audio error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: showLimitDialog,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Expense>('expenses').listenable(),
        builder: (context, Box<Expense> box, _) {
          final allExpenses = box.values.toList().cast<Expense>();
          final filtered = applyFilter(allExpenses);
          final total = filtered.fold<double>(0, (sum, e) => sum + e.amount);

          final now = DateTime.now();
          final thisMonthExpenses = allExpenses.where((e) =>
          e.date.month == now.month && e.date.year == now.year).toList();
          final totalSpentThisMonth = thisMonthExpenses.fold<double>(0, (sum, e) => sum + e.amount);
          final daysSpent = thisMonthExpenses.map((e) => e.date.day).toSet();
          final lastDay = daysSpent.isNotEmpty ? daysSpent.reduce((a, b) => a > b ? a : b) : now.day;
          final daysRemaining = 30 - lastDay;

          if (total > expenseLimit && !hasShownLimitWarning) {
            hasShownLimitWarning = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              playLimitSound();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ Budget limit ₹${expenseLimit.toInt()} exceeded!'),
                  backgroundColor: Colors.red.shade400,
                ),
              );
            });
          } else if (total <= expenseLimit && hasShownLimitWarning) {
            hasShownLimitWarning = false;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by category...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.trim()),
                ),
                const SizedBox(height: 16),

                /// Gemini AI Box
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  color: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("🧠 AI Budget Advisor", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (isLoadingAI)
                          const Center(child: CircularProgressIndicator())
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (aiText.isNotEmpty) Text(aiText),
                              if (customPromptResult.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(customPromptResult),
                                ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _promptController,
                          decoration: const InputDecoration(
                            hintText: 'Ask something (custom prompt)...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: () => fetchAI(totalSpentThisMonth, daysRemaining),
                              child: const Text("Get Auto Suggestion"),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final prompt = _promptController.text.trim();
                                if (prompt.isEmpty) return;
                                setState(() {
                                  isLoadingAI = true;
                                  customPromptResult = '';
                                });
                                final result = await GeminiBridgeService.getSuggestion(prompt);
                                setState(() {
                                  customPromptResult = result;
                                  isLoadingAI = false;
                                });
                              },
                              child: const Text("Send Custom Prompt"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                ExpensePieChart(expenses: filtered),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: FilterType.values.map((type) {
                    final label = switch (type) {
                      FilterType.oneDay => '1D',
                      FilterType.oneWeek => '1W',
                      FilterType.oneMonth => '1M',
                      FilterType.all => 'All',
                    };
                    return FilterChip(
                      label: Text(label),
                      selected: selectedFilter == type,
                      onSelected: (_) => updateFilter(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Recent Expenses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(height: 10),

                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 30),
                    child: Center(child: Text('No expenses found.')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final expense = filtered[index];
                      return Dismissible(
                        key: ValueKey(expense.key),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          final deleted = expense;
                          final deletedKey = deleted.key;
                          await Hive.box<Expense>('expenses').delete(deletedKey);
                          await Future.delayed(const Duration(milliseconds: 10));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Expense deleted'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  Hive.box<Expense>('expenses').put(deletedKey, deleted);
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: Image.asset(
                              categoryIcons[expense.category] ?? 'assets/images/others.png',
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                            ),
                            title: Text(expense.category),
                            subtitle: Text(DateFormat('yyyy-MM-dd').format(expense.date)),
                            trailing: Text(
                              '₹${expense.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                onExpenseAdded: () {},
                onToggleTheme: widget.onToggleTheme,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
