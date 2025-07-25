import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp(
    String email,
    String password, {
    required bool agreedToTerms,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCred.user!.sendEmailVerification();

    // Kullanıcıyı Firestore’a ekle
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userCred.user!.uid)
        .set({
          'email': email,
          'agreedToTerms': agreedToTerms,
          'agreedAt': FieldValue.serverTimestamp(),
        });

    return userCred.user;
  }

  Future<User?> signIn(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = userCred.user;

    if (user != null && user.emailVerified) {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await userDoc.get();

      if (!doc.exists) {
        final prefs = await SharedPreferences.getInstance();
        final agreed = prefs.getBool('temp_agreed') ?? false;

        await userDoc.set({
          'email': email,
          'agreedToTerms': agreed,
          'agreedAt': FieldValue.serverTimestamp(),
        });

        prefs.remove('temp_agreed');
      }
    }

    return user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
