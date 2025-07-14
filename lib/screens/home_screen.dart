import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thrifty/screens/analysis_screen.dart';
import '../models/expense.dart';
import '../screens/add_expense_screen.dart';
import '../widgets/expense_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/limit_service.dart';
import '../screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  double? _dailyLimit;

  @override
  void initState() {
    super.initState();
    _loadDailyLimit();
  }

  void _loadDailyLimit() async {
    final limit = await LimitService.getDailyLimit(_selectedDate);
    setState(() {
      _dailyLimit = limit;
    });
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadDailyLimit();
    }
  }

  void _setLimit() async {
    final controller = TextEditingController();
    final limitStr = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Günlük Harcama Limiti Belirle'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Tutar ₺'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (limitStr != null && double.tryParse(limitStr) != null) {
      final limit = double.parse(limitStr);
      await LimitService.setDailyLimit(_selectedDate, limit);
      _loadDailyLimit();
    }
  }

  Stream<List<Expense>> _fetchExpenses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: startOfDay)
        .where('date', isLessThan: endOfDay)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Expense.fromMap(doc.data())).toList(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('d MMMM y', 'tr_TR').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('Thrifty - $formattedDate'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Tarih Seç'),
          ),
          TextButton.icon(icon: const Icon(Icons.money), onPressed: _setLimit,label: const Text('Limit Belirle')),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: _fetchExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final expenses = snapshot.data ?? [];
                final total = expenses.fold<double>(
                  0.0,
                  (sum, item) => sum + item.amount,
                );

                String limitText;
                Color limitColor;

                if (_dailyLimit == null) {
                  limitText = 'Limit belirlenmedi.';
                  limitColor = Colors.grey;
                } else if (total > _dailyLimit!) {
                  final exceeded = total - _dailyLimit!;
                  limitText = '⚠ Limit ₺${exceeded.toStringAsFixed(2)} aşıldı! Limit: ₺${_dailyLimit!.toStringAsFixed(2)}';
                  limitColor = Colors.red;
                } else {
                  limitText = 'Limit: ₺${_dailyLimit!.toStringAsFixed(2)}';
                  limitColor = Colors.green;
                }

                if (expenses.isEmpty) {
                  return const Center(
                    child: Text('Bu tarihe ait harcama yok.'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            'Toplam Harcama: ₺${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            limitText,
                            style: TextStyle(
                              color: limitColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(
                          bottom: 100,
                        ), // FAB için boşluk bırak
                        itemCount: expenses.length,
                        itemBuilder: (context, index) =>
                            ExpenseCard(expense: expenses[index]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'analysis',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalysisScreen()),
              );
            },
            child: const Icon(Icons.analytics),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
