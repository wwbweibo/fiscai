import 'dart:convert';
import 'dart:async';
import 'dart:developer';
import 'package:http/http.dart' as http;
import '../models/bill.dart';
import '../llmtools/record_bill.dart';
import '../llmtools/list_bill.dart';

class AIAssistantService {
  final String apiKey;
  final String baseUrl;
  final String model;
  
  AIAssistantService({required this.apiKey, required this.baseUrl, required this.model});

  // Send message to AI and get streaming response
  Stream<String> sendMessageStream(String message, List<Map<String, dynamic>> history) async* {
    try {
      final messages = [
        {
          'role': 'system',
          'content': ''' CURRENT_DATE: ${DateTime.now().toIso8601String()}
你是FiscAI, 一个财务助手, 帮助用户管理他们的账单.

你可以帮助用户:
1. 记录账单, 使用create_bill工具来帮助用户记录账单。在记录账单时，账单的分类请使用用户提供的分类，日期如果没有明确指定，请使用当前日期，支付方式如果没有明确指定，请使用支付宝。
2. 列出并分析用户的账单，使用list_bills工具来帮助用户列出账单，并根据账单来分析用户的财务状况。提出切实可行的建议。

用户的账单分类如下:

${Bill.categories.join(', ')}

作为财务助手, 你的语气可以保持轻松幽默。
如果你需要更多信息, 请自然地询问.
'''
        },
        ...history,
      ];

      final createBillTool = createBillToolModel();
      final listBillsTool = listBillsToolModel();
      final tools = [createBillTool, listBillsTool];
      final response = await callLLM(messages, tools);
      await for (final line in response) {
        yield line;
      }
    } catch (e) {
      print('Error calling AI API: $e');
      yield 'Error calling AI API: $e';
    }
  }

  // Parse bill information from user message (non-streaming)
  Future<Bill?> parseBillFromMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''
You are a financial assistant that extracts bill information from user input. 
Always respond with a JSON object containing: title, amount, date (in YYYY-MM-DD format), 
category, description, paymentMethod, isIncome (boolean). Do not include any other text.
If the date is not specified, use today's date.
If the category is not specified, choose the most appropriate from: 餐饮, 交通, 购物, 娱乐, 医疗, 教育, 住房, 其他.
If the payment method is not specified, use 现金.
If it's not clearly income, assume it's an expense (isIncome: false).
Example response:
{
  "title": "咖啡",
  "amount": 35.0,
  "date": "2023-06-15",
  "category": "餐饮",
  "description": "在星巴克购买咖啡",
  "paymentMethod": "微信支付",
  "isIncome": false
}
'''
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Try to parse the JSON from the AI response
        try {
          // Extract JSON from the response if it's wrapped in other text
          final start = content.indexOf('{');
          final end = content.lastIndexOf('}') + 1;
          
          if (start >= 0 && end > start) {
            final jsonStr = content.substring(start, end);
            final billData = jsonDecode(jsonStr);
            
            return Bill(
              title: billData['title'],
              amount: billData['amount'] is int 
                ? (billData['amount'] as int).toDouble() 
                : billData['amount'].toDouble(),
              date: DateTime.parse(billData['date']),
              category: billData['category'],
              description: billData['description'],
              paymentMethod: billData['paymentMethod'],
              isIncome: billData['isIncome'],
            );
          }
        } catch (e) {
          print('Error parsing bill from message: $e');
          return null;
        }
      } else {
        print('AI API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error calling AI API: $e');
      return null;
    }
    return null;
  }
  
  // Check if message contains bill information
  Future<bool> containsBillInfo(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''
Determine if the user's message contains information about a financial transaction (bill or income).
Respond with only "YES" if it contains transaction information, or "NO" if it doesn't.
'''
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].trim().toUpperCase();
        return content == 'YES';
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking for bill info: $e');
      return false;
    }
  }
  
  // Determine user intent
  Future<String> determineIntent(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'system',
              'content': '''
Determine the user's intent from their message. Possible intents are:
- "add_bill" - if they want to add a bill/transaction
- "list_bills" - if they want to see their bills
- "analyze_bills" - if they want to analyze their bills
- "other" - for any other intent

Respond with only one of these exact values.
'''
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'temperature': 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim().toLowerCase();
      } else {
        return 'other';
      }
    } catch (e) {
      print('Error determining intent: $e');
      return 'other';
    }
  }

  Future<http.StreamedResponse> streamRequest(http.Request request) async {
    final client = http.Client();
    final response = await client.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      log('HTTP error: ${response.statusCode}, $body');
      throw Exception('HTTP error: ${response.statusCode}');
    }
    return response;
  }

  Stream<String> callLLM(List<Map<String, dynamic>> messages, List<Map<String, dynamic>> tools) async* {
    while (true) {
      final request = http.Request('POST', Uri.parse('$baseUrl/v1/chat/completions'));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      });
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
        'temperature': 0.7,
        'tools': tools,
      });

      var response = await streamRequest(request);
      var allContent = "";
      final toolCallsCache = <int, Map<String, dynamic>>{};
      final toolCallsResult = <String, dynamic>{};
      bool hasToolCalls = false;
      
      await for (final line in response.stream
        .timeout(Duration(seconds: 30))
        .transform(utf8.decoder)
        .transform(LineSplitter())) {
          if (line.isEmpty) continue;
          
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            
            if (data == '[DONE]') {
              log('Stream completed');
              break;
            }
            
            try {
              final json = jsonDecode(data);
              final choices = json['choices'] as List?;
              
              if (choices != null && choices.isNotEmpty) {
                final choice = choices[0];
                final delta = choice['delta'];
                final finishReason = choice['finish_reason'];
                final content = delta?['content'];
                final toolCalls = delta?['tool_calls'];
                
                // 收集工具调用信息
                if (toolCalls != null && toolCalls is List) {
                  hasToolCalls = true;
                  for (final toolCall in toolCalls) {
                    final idx = toolCall['index'] as int;
                    final id = toolCall['id'] ?? '';
                    final name = toolCall['function']?['name'] ?? '';
                    final args = toolCall['function']?['arguments'] ?? '';
                    
                    if (toolCallsCache.containsKey(idx)) {
                      final cached = toolCallsCache[idx]!;
                      cached['id'] = (cached['id'] ?? '') + id;
                      cached['name'] = (cached['name'] ?? '') + name;
                      cached['args'] = (cached['args'] ?? '') + args;
                    } else {
                      toolCallsCache[idx] = {
                        'id': id,
                        'name': name,
                        'args': args,
                      };
                    }
                  }
                }
                
                // 处理工具调用完成
                if (finishReason == 'tool_calls' && hasToolCalls) {
                  log('Processing tool calls: ${toolCallsCache.length}');
                  
                  for (final toolCall in toolCallsCache.values) {
                    final toolCallId = toolCall['id'] as String;
                    final toolCallName = toolCall['name'] as String;
                    final toolCallArgs = toolCall['args'] as String;
                    
                    try {
                      final result = await executeToolCall(toolCallId, toolCallName, toolCallArgs);
                      toolCallsResult[toolCallId] = result;
                      // 添加LLM的回复
                      messages.add({
                        'role': 'assistant',
                        'content': allContent,
                        'function_call': null,
                        "tool_calls": [
                          {
                            "id": toolCallId,
                            "type": "function",
                            "function": {
                              "name": toolCallName,
                              "arguments": toolCallArgs,
                            }
                          }
                        ]
                      });
                      // 添加工具调用的回复
                      messages.add({
                        'role': 'tool',
                        'tool_call_id': toolCallId,
                        'content': jsonEncode(result),
                      });
                    } catch (e) {
                      log('Tool execution error: $e');
                      toolCallsResult[toolCallId] = {'error': e.toString()};
                    }
                  }
                  break;
                }

                if (content != null && content is String && content.isNotEmpty) {
                  log('Received content: $content');
                  allContent += content;
                  yield content;
                }
              }
            } catch (e) {
              log('Error parsing chunk: $e, data: $data');
            }
          }
        }
        
      // 如果没有工具调用，退出循环
      if (!hasToolCalls) {
        break;
      }
    }
  }

  Future<dynamic> executeToolCall(String toolCallId, String toolCallName, String toolCallArgs) async {
    if (toolCallName == 'create_bill') {
      return await callInsertBill(toolCallArgs);
    }
    if (toolCallName == 'list_bills') {
      return await callListBills(toolCallArgs);
    }
    return {'error': 'Unknown tool: $toolCallName'};
  }

  Future<int> callInsertBill(String args) async {
    try {
      log('callInsertBill args: $args');
      final parsedArgs = jsonDecode(args);
      
      // 如果参数直接是bill数据，使用它；否则查找'bill'字段
      final billData = parsedArgs is Map && parsedArgs.containsKey('bill') 
        ? parsedArgs['bill'] 
        : parsedArgs;
      final bill = Bill.fromMap(billData);
      return await createBillTool(bill);
    } catch (e) {
      log('Error in callInsertBill: $e');
      throw Exception('Failed to create bill: $e');
    }
  }

  Future<List<Map<String, dynamic>>> callListBills(String args) async {
    try {
      log('callListBills args: $args');
      final parsedArgs = jsonDecode(args);
      final query = BillQuery.fromMap(parsedArgs['query']);
      final bills = await listBillsTool(query);
      return bills.map((bill) => bill.toMap()).toList();
    } catch (e) {
      log('Error in callListBills: $e');
      throw Exception('Failed to list bills: $e');
    }
  }
}