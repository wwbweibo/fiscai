import 'dart:developer';
import 'package:flutter/material.dart';
import '../models/bill.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../services/ai_assistant_service.dart';
import '../utils/app_config.dart';

class BillProvider with ChangeNotifier {
  List<Bill> _bills = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _chatHistory = [];

  List<Bill> get bills => _bills;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get chatHistory => _chatHistory;

  // Load bills from database
  Future<void> loadBills() async {
    _isLoading = true;
    notifyListeners();

    try {
      _bills = await DatabaseService().getAllBills();
      for (var bill in _bills) {
        log('bill: ${bill.toMap()}');
      }
    } catch (e) {
      print('Error loading bills: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add a new bill
  Future<void> addBill(Bill bill) async {
    try {
      final id = await DatabaseService().insertBill(bill);
      _bills.add(bill.copyWith(id: id));
      notifyListeners();
    } catch (e) {
      print('Error adding bill: $e');
    }
  }

  // Add a bill using AI from text
  Future<Bill?> addBillFromText(String text, AIService aiService) async {
    try {
      final bill = await aiService.parseBillFromText(text);
      if (bill != null) {
        await addBill(bill);
        return bill;
      }
    } catch (e) {
      print('Error adding bill from text: $e');
    }
    return null;
  }

  // Send message to AI assistant and get streaming response
  Stream<String> sendToAIAssistantStream(String message, AIAssistantService aiAssistant) async* {
    try {
      // Add user message to history
      _chatHistory.add({'role': 'user', 'content': message});
      notifyListeners();

      // Get streaming response from AI
      yield* aiAssistant.sendMessageStream(_chatHistory);
    } catch (e) {
      print('Error sending message to AI assistant: $e');
      yield '抱歉，我遇到了一些问题，请稍后再试。';
    }
  }

  // Process user message to extract and add bill
  Future<Bill?> processUserMessage(String message, AIAssistantService aiAssistant) async {
    try {
      // Check if message contains bill information
      final hasBillInfo = await aiAssistant.containsBillInfo(message);
      
      if (hasBillInfo) {
        // Extract bill information
        final bill = await aiAssistant.parseBillFromMessage(message);
        if (bill != null) {
          await addBill(bill);
          return bill;
        }
      }
      
      return null;
    } catch (e) {
      print('Error processing user message: $e');
      return null;
    }
  }

  // Determine user intent
  Future<String> determineUserIntent(String message, AIAssistantService aiAssistant) async {
    return await aiAssistant.determineIntent(message);
  }

  // Add AI response to chat history
  void addAIResponseToHistory(String response) {
    _chatHistory.add({'role': 'assistant', 'content': response});
    notifyListeners();
  }

  // Clear chat history
  void clearChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }

  // Update a bill
  Future<void> updateBill(Bill bill) async {
    try {
      await DatabaseService().updateBill(bill);
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating bill: $e');
    }
  }

  // Delete a bill
  Future<void> deleteBill(int id) async {
    try {
      await DatabaseService().deleteBill(id);
      _bills.removeWhere((bill) => bill.id == id);
      notifyListeners();
    } catch (e) {
      print('Error deleting bill: $e');
    }
  }
  
  // Create AI assistant with current config
  AIAssistantService createAIAssistant() {
    return AIAssistantService(
      apiKey: AppConfig.apiKey,
      baseUrl: AppConfig.baseUrl,
      model: AppConfig.model,
    );
  }
}

// Extension to allow copying a Bill with modified properties
extension BillCopyWith on Bill {
  Bill copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    String? category,
    String? description,
    String? paymentMethod,
    bool? isIncome,
  }) {
    return Bill(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}