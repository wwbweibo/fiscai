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

  static const List<String> categories = ['餐饮', '交通', '购物', '娱乐', '医疗', '教育', '住房', '工资', '奖金', '投资', '理财', '其他'];

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

class BillQuery {
  DateTime? dateBegin;
  DateTime? dateEnd;
  String? category;
  bool? isIncome;

  BillQuery({this.dateBegin, this.dateEnd, this.category, this.isIncome});

  factory BillQuery.fromMap(Map<String, dynamic> map) {
    
    return BillQuery(
      dateBegin: map['dateBegin'] != null ? DateTime.parse(map['dateBegin']) : null,
      dateEnd: map['dateEnd'] != null ? DateTime.parse(map['dateEnd']) : null,
      category: map['category'] != null ? map['category'] : null,
      isIncome: map['isIncome'] != null ? map['isIncome'] : null,
    );
  }
}