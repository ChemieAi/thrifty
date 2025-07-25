import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thrifty/screens/login_screen.dart';
import 'package:thrifty/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptedTerms = false;

  final String _termsText = '''
1. Uygulamanın doğru kullanımı kullanıcıya aittir.
2. Yanlış bilgi girilmesi durumunda sistem sorumluluk kabul etmez.
3. Harcamaların takibi kullanıcıya bağlıdır.
''';

  final String _privacyText = '''
1. Email ve şifre bilgileriniz gizli tutulur.
2. Üçüncü taraflarla veri paylaşımı yapılmaz.
3. Firebase servisleri güvenli şekilde kullanılır.
''';

  void _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Şifreler uyuşmuyor")),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanım Şartlarını kabul etmelisiniz.")),
      );
      return;
    }

    try {
      // Firebase Auth ile kullanıcı kaydı
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        agreedToTerms: _acceptedTerms,
      );

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Firestore'a agreedToTerms ve balance yaz
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('meta')
          .set({
        'email': _emailController.text.trim(),
        'agreedToTerms': _acceptedTerms,
        'agreedAt': DateTime.now(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('balance')
          .set({
        'cash': 0,
        'card': 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kayıt başarılı, giriş yapabilirsiniz.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kayıt başarısız: $e")),
      );
    }
  }

  void _showPolicyModal(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Şifre',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _acceptedTerms,
                    onChanged: (val) =>
                        setState(() => _acceptedTerms = val ?? false),
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text('Şunları kabul ediyorum: '),
                        GestureDetector(
                          onTap: () => _showPolicyModal(
                            context,
                            'Kullanım Şartları',
                            _termsText,
                          ),
                          child: const Text(
                            'Kullanım Şartları',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const Text(' ve '),
                        GestureDetector(
                          onTap: () => _showPolicyModal(
                            context,
                            'Gizlilik Politikası',
                            _privacyText,
                          ),
                          child: const Text(
                            'Gizlilik Politikası',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _register, child: const Text('Kayıt')),
            ],
          ),
        ),
      ),
    );
  }
}
