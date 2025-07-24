class Bill {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final String description;
  final String paymentMethod;
  final bool isIncome;

  Bill({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.description,
    required this.paymentMethod,
    required this.isIncome,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toString(),
      'category': category,
      'description': description,
      'paymentMethod': paymentMethod,
      'isIncome': isIncome ? 1 : 0,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      description: map['description'],
      paymentMethod: map['paymentMethod'],
      isIncome: map['isIncome'] == 1,
    );
  }
}