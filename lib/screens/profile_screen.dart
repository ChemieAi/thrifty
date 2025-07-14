import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/balance_service.dart';
import '../models/balance_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Balance? _balance;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final bal = await BalanceService.getBalance();
    setState(() => _balance = bal);
  }

  void _showBalanceDialog(String type) async {
    final controller = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$type bakiyesi güncelle'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Yeni bakiye (₺)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Güncelle')),
        ],
      ),
    );

    if (action != null && double.tryParse(action) != null) {
      final newAmount = double.parse(action);
      if (type == 'Nakit') {
        await BalanceService.updateBalance(cash: newAmount);
      } else {
        await BalanceService.updateBalance(card: newAmount);
      }
      _loadBalance();
    }
  }

  Widget _buildBalanceCard(String label, double amount, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label),
        trailing: Text(
          '₺${amount.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () => _showBalanceDialog(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final total =
        _balance == null ? 0 : _balance!.cash + _balance!.card;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _balance == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Email: ${user?.email ?? "Bilinmiyor"}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Toplam Bakiye: ₺${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildBalanceCard('Nakit', _balance!.cash, Icons.wallet),
                  _buildBalanceCard('Kart', _balance!.card, Icons.credit_card),
                ],
              ),
            ),
    );
  }
}
