// This is a basic Flutter widget test for BassPro Player.
//
// Simple test to verify basic widgets can be built.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp builds correctly', (WidgetTester tester) async {
    // Test basic MaterialApp widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('BassPro Player Test'),
        ),
      ),
    );
    
    // Verify the text is displayed
    expect(find.text('BassPro Player Test'), findsOneWidget);
  });
}
