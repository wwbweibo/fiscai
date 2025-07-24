import 'package:fiscai/models/bill.dart';
import 'package:fiscai/services/database_service.dart';

Future<int> createBillTool(Bill bill) async {
  final database = DatabaseService();
  return await database.insertBill(bill);
}

Map<String, dynamic> createBillToolModel() {
  return {
    "type": "function",
    "function": {
      "name": "create_bill",
      "description": "创建账单",
      "parameters": {
        "type": "object",
        "properties": {
          "bill": {
            "type": "object",
            "properties": {
              "title": {"type": "string", "description": "账单标题"},
              "amount": {"type": "number", "description": "账单金额, 保留两位小数"},
              "type": {"type": "string", "description": "账单类型, 支出, 收入"},
              "category": {"type": "string", "description": "账单分类，从用户的输入中推测"},
              "date": {"type": "string", "description": "账单日期, 格式为YYYY-MM-DD, 默认为当前日期"},
              "description": {"type": "string", "description": "账单描述"},
              "paymentMethod": {"type": "string", "description": "支付方式, 现金, 银行卡, 微信, 支付宝, 信用卡; 默认为现金"},
              "isIncome": {"type": "number", "description": "是否是收入, 1是, 0否"},
            },
            "required": [
              "title",
              "amount",
              "type",
              "category",
              "date",
              "description",
              "paymentMethod",
              "isIncome",
            ],
          },
        },
        "required": ["bill"],
      },
    },
  };
}
