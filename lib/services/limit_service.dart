// lib/services/limit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LimitService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> setDailyLimit(DateTime date, double amount) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docId = _formatDate(date);
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('limits')
        .doc(docId)
        .set({'limit': amount});
  }

  static Future<double?> getDailyLimit(DateTime date) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docId = _formatDate(date);
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('limits')
        .doc(docId)
        .get();

    return doc.data()?['limit']?.toDouble();
  }

  static String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
