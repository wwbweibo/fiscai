import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bill.dart';

class AIService {
  // This would be configured by the user
  final String apiKey;
  final String baseUrl;
  
  AIService({required this.apiKey, required this.baseUrl});

  // Parse bill information from user text input
  Future<Bill?> parseBillFromText(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a financial assistant that extracts bill information from user input. Always respond with a JSON object containing: title, amount, date (in YYYY-MM-DD format), category, description, paymentMethod, isIncome (boolean).'
            },
            {
              'role': 'user',
              'content': text
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
          final billData = jsonDecode(content);
          return Bill(
            title: billData['title'],
            amount: billData['amount'].toDouble(),
            date: DateTime.parse(billData['date']),
            category: billData['category'],
            description: billData['description'],
            paymentMethod: billData['paymentMethod'],
            isIncome: billData['isIncome'],
          );
        } catch (e) {
          print('Error parsing AI response: $e');
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
  }

  // Placeholder for image recognition - would use a different API endpoint
  Future<Bill?> parseBillFromImage(String imagePath) async {
    // In a real implementation, this would send the image to an AI service
    // that can perform OCR and extract bill information
    print('Image recognition not implemented yet');
    return null;
  }

  // Placeholder for voice recognition - would use a different API endpoint
  Future<Bill?> parseBillFromVoice(String voiceData) async {
    // In a real implementation, this would send the voice data to an AI service
    // that can perform speech-to-text and extract bill information
    print('Voice recognition not implemented yet');
    return null;
  }
}