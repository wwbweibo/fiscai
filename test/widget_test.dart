// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:fiscai/main.dart';
import 'package:fiscai/providers/bill_provider.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => BillProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the app title is displayed.
    expect(find.text('FiscAI - 斐账'), findsOneWidget);
    
    // Verify that we can find the bottom navigation bar items.
    expect(find.byIcon(Icons.list), findsOneWidget);
    expect(find.byIcon(Icons.analytics), findsOneWidget);
    expect(find.byIcon(Icons.chat), findsOneWidget); // Changed from Icons.add to Icons.chat
  });
}
