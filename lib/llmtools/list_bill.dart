import 'package:fiscai/models/bill.dart';
import 'package:fiscai/services/database_service.dart';

Future<List<Bill>> listBillsTool(BillQuery query) async {
  final database = DatabaseService();
  return await database.listBills(query);
}

Map<String, dynamic> listBillsToolModel() {
  return {
    "type": "function",
    "function": {
      "name": "list_bills",
      "description": "列出账单",
      "parameters": {
        "type": "object",

        "properties": {
          "query": {
            "type": "object",
            "properties": {
              "dateBegin": {"type": "string", "description": "开始日期"},
              "dateEnd": {"type": "string", "description": "结束日期"},
              "category": {"type": "string", "description": "分类"},
              "isIncome": {"type": "boolean", "description": "是否是收入"},
            },
            "required": [],
          }
        },
        "required": ["query"],
      },
    },
  };
}
