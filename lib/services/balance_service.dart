import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/balance_model.dart';

class BalanceService {
  static final _db = FirebaseFirestore.instance;
  static final _uid = FirebaseAuth.instance.currentUser!.uid;

  static Future<Balance> getBalance() async {
    final doc = await _db.collection('users').doc(_uid).collection('settings').doc('balance').get();
    if (!doc.exists) return Balance(cash: 0, card: 0);
    return Balance.fromMap(doc.data()!);
  }

  static Future<void> updateBalance({double? cash, double? card}) async {
    final current = await getBalance();
    final newBalance = Balance(
      cash: cash ?? current.cash,
      card: card ?? current.card,
    );
    await _db.collection('users').doc(_uid).collection('settings').doc('balance').set(newBalance.toMap());
  }

  static Future<void> subtractFromBalance({required String type, required double amount}) async {
    final current = await getBalance();
    if (type == 'cash') {
      await updateBalance(cash: current.cash - amount);
    } else {
      await updateBalance(card: current.card - amount);
    }
  }
}
