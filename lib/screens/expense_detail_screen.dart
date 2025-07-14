import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;

  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'd MMMM y, HH:mm',
      'tr_TR',
    ).format(expense.date.toLocal());

    return Scaffold(
      appBar: AppBar(title: const Text('Harcama Detayı')),
      body: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: FractionallySizedBox(
            widthFactor: 0.9,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Açıklama',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      expense.description,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kategori',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(expense.category.toUpperCase()),
                    const SizedBox(height: 16),
                    const Text(
                      'Tutar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('₺${expense.amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Tarih ve Saat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(dateStr),
                    const SizedBox(height: 16),
                    const Text(
                      'Ödeme Türü',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(expense.paymentType == 'cash' ? 'Nakit' : 'Kart'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
