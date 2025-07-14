import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';

enum AnalysisRange { daily, weekly, monthly, all }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  DateTime _selectedDate = DateTime.now();
  AnalysisRange _range = AnalysisRange.daily;

  Map<String, double> _categoryTotals = {};
  bool _loading = false;

  Future<void> _fetchData() async {
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Query query = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');

    // Tarih aralığını belirle
    DateTime? start;
    DateTime? end;

    switch (_range) {
      case AnalysisRange.daily:
        start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        end = start.add(const Duration(days: 1));
        break;
      case AnalysisRange.weekly:
        final weekday = _selectedDate.weekday;
        start = _selectedDate.subtract(Duration(days: weekday - 1)); // Pazartesi
        end = start.add(const Duration(days: 7));
        break;
      case AnalysisRange.monthly:
        start = DateTime(_selectedDate.year, _selectedDate.month, 1);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
        break;
      case AnalysisRange.all:
        start = null;
        end = null;
        break;
    }

    if (start != null && end != null) {
      query = query.where('date', isGreaterThanOrEqualTo: start).where('date', isLessThan: end);
    }

    final snapshot = await query.get();
    final expenses = snapshot.docs
        .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final totals = <String, double>{};
    for (var expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    setState(() {
      _categoryTotals = totals;
      _loading = false;
    });
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      _fetchData();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  String _getFormattedRangeLabel() {
    final formatter = DateFormat('d MMM y', 'tr_TR');
    switch (_range) {
      case AnalysisRange.daily:
        return formatter.format(_selectedDate);
      case AnalysisRange.weekly:
        final start = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return '${formatter.format(start)} - ${formatter.format(end)}';
      case AnalysisRange.monthly:
        return DateFormat('MMMM y', 'tr_TR').format(_selectedDate);
      case AnalysisRange.all:
        return 'Tüm Zamanlar';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Analizi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
            tooltip: 'Tarih Seç',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('Aralık: '),
                DropdownButton<AnalysisRange>(
                  value: _range,
                  onChanged: (newValue) {
                    if (newValue != null) {
                      setState(() => _range = newValue);
                      _fetchData();
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: AnalysisRange.daily,
                      child: Text('Günlük'),
                    ),
                    DropdownMenuItem(
                      value: AnalysisRange.weekly,
                      child: Text('Haftalık'),
                    ),
                    DropdownMenuItem(
                      value: AnalysisRange.monthly,
                      child: Text('Aylık'),
                    ),
                    DropdownMenuItem(
                      value: AnalysisRange.all,
                      child: Text('Tüm Zamanlar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Seçim: ${_getFormattedRangeLabel()}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _categoryTotals.isEmpty
                    ? const Center(child: Text('Veri bulunamadı.'))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _categoryTotals.length,
                        itemBuilder: (context, index) {
                          final entry = _categoryTotals.entries.elementAt(index);
                          return ListTile(
                            leading: const Icon(Icons.label),
                            title: Text(entry.key.toUpperCase()),
                            trailing: Text('₺${entry.value.toStringAsFixed(2)}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
