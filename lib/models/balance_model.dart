class Balance {
  final double cash;
  final double card;

  Balance({required this.cash, required this.card});

  Map<String, dynamic> toMap() {
    return {
      'cash': cash,
      'card': card,
    };
  }

  factory Balance.fromMap(Map<String, dynamic> map) {
    return Balance(
      cash: (map['cash'] ?? 0).toDouble(),
      card: (map['card'] ?? 0).toDouble(),
    );
  }
}
