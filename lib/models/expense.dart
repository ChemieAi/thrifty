// lib/models/expense.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum Category { food, transport, entertainment, other }

class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final Category category;

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date, // ✅ direkt DateTime (Firestore Timestamp olarak saklar)
      'category': category.name,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: (map['date'] as Timestamp).toDate(),
      category: Category.values.byName(map['category']),
    );
  }
}
