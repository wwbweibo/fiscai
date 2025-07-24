import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/bill_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadConfig();
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => BillProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData lightSciFiTheme = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: const Color(0xFF2563EB),
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF2563EB),
        onPrimary: Colors.white,
        secondary: const Color(0xFF06B6D4),
        onSecondary: Colors.white,
        background: const Color(0xFFF8FAFC),
        onBackground: const Color(0xFF1E293B),
        surface: Colors.white,
        onSurface: const Color(0xFF1E293B),
        surfaceVariant: const Color(0xFFF1F5F9),
        outline: const Color(0xFF64748B),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      cardColor: Colors.white,
      dialogBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Color(0xFF1E293B), fontSize: 16),
        bodyLarge: TextStyle(color: Color(0xFF1E293B), fontSize: 18),
        titleMedium: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF06B6D4)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
    );

    return MaterialApp(
      title: 'FiscAI - 斐账',
      theme: lightSciFiTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
