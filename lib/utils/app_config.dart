import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _apiKeyKey = 'api_key';
  static const String _baseUrlKey = 'base_url';
  static const String _modelKey = 'model';
  
  static const String defaultBaseUrl = 'https://api.openai.com/v1';
  static const String defaultModel = 'gpt-3.5-turbo';
  
  static String apiKey = '';
  static String baseUrl = defaultBaseUrl;
  static String model = defaultModel;
  
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString(_apiKeyKey) ?? '';
    baseUrl = prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
    model = prefs.getString(_modelKey) ?? defaultModel;
  }
  
  static Future<void> saveConfig(String newApiKey, String newBaseUrl, String newModel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, newApiKey);
    await prefs.setString(_baseUrlKey, newBaseUrl);
    await prefs.setString(_modelKey, newModel);
    
    // Update static variables
    apiKey = newApiKey;
    baseUrl = newBaseUrl;
    model = newModel;
  }
}