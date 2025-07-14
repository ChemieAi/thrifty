import 'package:cloud_firestore/cloud_firestore.dart';
class Expense {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String paymentType; // 'cash' ya da 'card'

  Expense({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.paymentType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date,
      'category': category,
      'paymentType': paymentType,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: (map['amount'] as num).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      category: map['category'],
      paymentType: map['paymentType'] ?? 'cash', // varsayılan
    );
  }
}
