// lib/widgets/expense_card.dart
import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;

  const ExpenseCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(_getCategoryIcon(expense.category), color: Colors.orange),
        title: Text(expense.description),
        subtitle: Text(DateFormat.yMMMd().format(expense.date)),
        trailing: Text('₺${expense.amount.toStringAsFixed(2)}'),
      ),
    );
  }

  IconData _getCategoryIcon(Category category) {
    switch (category) {
      case Category.food:
        return Icons.fastfood;
      case Category.transport:
        return Icons.directions_bus;
      case Category.entertainment:
        return Icons.movie;
      case Category.other:
      default:
        return Icons.money;
    }
  }
}
