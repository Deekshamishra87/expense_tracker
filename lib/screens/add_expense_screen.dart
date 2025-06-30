import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final VoidCallback? onExpenseAdded;
  final VoidCallback? onToggleTheme;

  const AddExpenseScreen({
    super.key,
    this.onExpenseAdded,
    this.onToggleTheme,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  DateTime? selectedDate;
  String? selectedCategory;

  final List<String> categories = [
    'Food',
    'Travel',
    'Shopping',
    'Rent',
    'Bills',
    'Entertainment',
    'Work',
    'Other',
  ];

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

  void pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void saveExpense({bool shouldPop = false}) {
    final category = selectedCategory?.trim() ?? '';
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (category.isEmpty || amount == null || amount <= 0 || selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    final newExpense = Expense(
      category: category,
      amount: amount,
      date: selectedDate!,
    );

    final box = Hive.box<Expense>('expenses');
    box.add(newExpense);

    widget.onExpenseAdded?.call();

    amountController.clear();
    setState(() {
      selectedDate = null;
      selectedCategory = null;
    });

    FocusScope.of(context).unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Expense saved!")),
    );

    if (shouldPop) Navigator.pop(context);
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(selectedDate!)
        : 'Select Date';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Expense',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Row(
                    children: [
                      if (categoryIcons.containsKey(category))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.asset(
                            categoryIcons[category]!,
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                          ),
                        ),
                      Text(category),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value);
              },
            ),
            const SizedBox(height: 20),

            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(formattedDate),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => saveExpense(shouldPop: true),
                    icon: const Icon(Icons.check),
                    label: const Text('Save & Go Back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => saveExpense(shouldPop: false),
                    icon: const Icon(Icons.add),
                    label: const Text('Save & Add Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
