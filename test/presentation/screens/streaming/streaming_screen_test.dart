import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/presentation/screens/streaming/streaming_screen.dart';

/// Tests for StreamingScreen widget
/// 
/// These tests verify:
/// - Screen renders correctly
/// - Stream list displays properly
/// - Add stream button is present
/// - Empty state displays when no streams
void main() {
  testWidgets('StreamingScreen displays correctly', (WidgetTester tester) async {
    // Build the StreamingScreen widget
    await tester.pumpWidget(
      const MaterialApp(
        home: StreamingScreen(),
      ),
    );

    // Wait for initial load
    await tester.pump();

    // Verify the app bar is displayed
    expect(find.text('Streaming'), findsOneWidget);
    
    // Verify the add button is present
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('StreamingScreen shows loading indicator initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StreamingScreen(),
      ),
    );

    // Should show loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('StreamingScreen shows empty state when no streams', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StreamingScreen(),
      ),
    );

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Should show empty state message
    expect(find.text('Aucune source de streaming'), findsOneWidget);
    expect(find.text('Ajoutez des flux radio ou podcasts'), findsOneWidget);
  });

  testWidgets('StreamingScreen shows sections headers', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StreamingScreen(),
      ),
    );

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Should show "All Sources" section header
    expect(find.text('Toutes les sources'), findsOneWidget);
  });

  testWidgets('Add stream button opens dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StreamingScreen(),
      ),
    );

    // Wait for loading to complete
    await tester.pumpAndSettle();

    // Tap the add button
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Should show the add stream dialog
    expect(find.text('Ajouter un flux'), findsOneWidget);
  });
}
