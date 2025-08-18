import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _apiKeyKey = 'api_key';
  static const String _baseUrlKey = 'base_url';
  static const String _modelKey = 'model';
  static const String _visionKey = 'vision';

  static String apiKey = '';
  static String baseUrl = '';
  static String model = '';
  static bool vision = false;
  
  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    apiKey = prefs.getString(_apiKeyKey) ?? '';
    baseUrl = prefs.getString(_baseUrlKey) ?? '';
    model = prefs.getString(_modelKey) ?? '';
    vision = prefs.getBool(_visionKey) ?? false;
  }
  
  static Future<void> saveConfig(String newApiKey, String newBaseUrl, String newModel, bool newVision) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, newApiKey);
    await prefs.setString(_baseUrlKey, newBaseUrl);
    await prefs.setString(_modelKey, newModel);
    await prefs.setBool(_visionKey, newVision);
    
    // Update static variables
    apiKey = newApiKey;
    baseUrl = newBaseUrl;
    model = newModel;
    vision = newVision;
  }
}