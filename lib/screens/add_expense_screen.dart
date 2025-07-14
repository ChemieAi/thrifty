import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/balance_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();

  final List<String> _predefinedCategories = [
    'food',
    'transport',
    'entertainment',
    'bills',
    'health',
    'shopping',
    'education',
    'travel',
    'gift',
    'Other',
  ];

  String _selectedCategory = 'food';
  bool _isCustomCategory = false;
  DateTime _selectedDate = DateTime.now();
  String _paymentType = 'cash'; // ✅ nakit varsayılan

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitExpense() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final category = _isCustomCategory
          ? _customCategoryController.text.trim()
          : _selectedCategory;

      final expense = Expense(
        id: const Uuid().v4(),
        description: _descController.text,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        category: category,
        paymentType: _paymentType,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expense.id)
          .set(expense.toMap());

      // ✅ Bakiyeden düş
      await BalanceService.subtractFromBalance(
        type: _paymentType,
        amount: expense.amount,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Harcama kaydedildi")));

      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat.yMMMMd('tr_TR').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Harcama Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Zorunlu alan' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Tutar (₺)'),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Zorunlu alan';
                  if (double.tryParse(val) == null) return 'Geçersiz sayı';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _predefinedCategories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedCategory = val;
                    _isCustomCategory = val == 'Other';
                  });
                },
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              if (_isCustomCategory)
                TextFormField(
                  controller: _customCategoryController,
                  decoration: const InputDecoration(labelText: 'Kategori adı'),
                  validator: (val) {
                    if (_isCustomCategory && (val == null || val.isEmpty)) {
                      return 'Kategori adı giriniz';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _paymentType,
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Nakit')),
                  DropdownMenuItem(value: 'card', child: Text('Kart')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _paymentType = val);
                },
                decoration: const InputDecoration(labelText: 'Ödeme Türü'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Tarih: $formattedDate'),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Tarih Seç'),
                    onPressed: _pickDate,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitExpense,
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
