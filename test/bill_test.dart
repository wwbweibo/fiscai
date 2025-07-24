import 'package:flutter_test/flutter_test.dart';
import 'package:fiscai/models/bill.dart';

void main() {
  group('Bill Model Tests', () {
    test('Bill creation and properties', () {
      final bill = Bill(
        id: 1,
        title: '午餐',
        amount: 25.50,
        date: DateTime(2023, 6, 15),
        category: '餐饮',
        description: '在公司附近餐厅用餐',
        paymentMethod: '支付宝',
        isIncome: false,
      );

      expect(bill.id, 1);
      expect(bill.title, '午餐');
      expect(bill.amount, 25.50);
      expect(bill.date, DateTime(2023, 6, 15));
      expect(bill.category, '餐饮');
      expect(bill.description, '在公司附近餐厅用餐');
      expect(bill.paymentMethod, '支付宝');
      expect(bill.isIncome, false);
    });

    test('Bill toMap conversion', () {
      final bill = Bill(
        id: 1,
        title: '工资',
        amount: 8000.00,
        date: DateTime(2023, 6, 10),
        category: '工资',
        description: '六月份工资',
        paymentMethod: '银行转账',
        isIncome: true,
      );

      final map = bill.toMap();

      expect(map['id'], 1);
      expect(map['title'], '工资');
      expect(map['amount'], 8000.00);
      expect(map['date'], DateTime(2023, 6, 10).millisecondsSinceEpoch);
      expect(map['category'], '工资');
      expect(map['description'], '六月份工资');
      expect(map['paymentMethod'], '银行转账');
      expect(map['isIncome'], 1);
    });

    test('Bill fromMap conversion', () {
      final map = {
        'id': 2,
        'title': '电影票',
        'amount': 45.00,
        'date': DateTime(2023, 6, 12).millisecondsSinceEpoch,
        'category': '娱乐',
        'description': '观看《速度与激情10》',
        'paymentMethod': '微信支付',
        'isIncome': 0,
      };

      final bill = Bill.fromMap(map);

      expect(bill.id, 2);
      expect(bill.title, '电影票');
      expect(bill.amount, 45.00);
      expect(bill.date, DateTime(2023, 6, 12));
      expect(bill.category, '娱乐');
      expect(bill.description, '观看《速度与激情10》');
      expect(bill.paymentMethod, '微信支付');
      expect(bill.isIncome, false);
    });
  });
}