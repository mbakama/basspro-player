import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/presentation/screens/library/library_screen.dart';

/// Widget tests for LibraryScreen search functionality.
/// 
/// Tests verify:
/// - Search icon toggles search mode
/// - Search field appears when search is active
/// - Tracks are filtered as user types
/// - Search works across title, artist, and album fields
/// - Empty state shows appropriate message when no results
/// - Closing search clears the query
void main() {
  group('LibraryScreen Search Functionality', () {
    testWidgets('should show search icon in app bar', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Verify search icon is present
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should toggle search mode when search icon is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Tap search icon
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Verify search field appears
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rechercher...'), findsOneWidget);
      
      // Verify close icon appears
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should filter tracks by title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Initially, all sample tracks should be visible
      expect(find.text('Exemple de Chanson 1'), findsOneWidget);
      expect(find.text('Chanson Test 2'), findsOneWidget);
      expect(find.text('Musique Demo 3'), findsOneWidget);

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Type search query that matches only one title
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Verify only matching track is shown
      expect(find.text('Chanson Test 2'), findsOneWidget);
      expect(find.text('Exemple de Chanson 1'), findsNothing);
      expect(find.text('Musique Demo 3'), findsNothing);
    });

    testWidgets('should filter tracks by artist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search by artist
      await tester.enterText(find.byType(TextField), 'Autre Artiste');
      await tester.pumpAndSettle();

      // Verify only matching track is shown
      expect(find.text('Chanson Test 2'), findsOneWidget);
      expect(find.text('Exemple de Chanson 1'), findsNothing);
      expect(find.text('Musique Demo 3'), findsNothing);
    });

    testWidgets('should filter tracks by album', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search by album
      await tester.enterText(find.byType(TextField), 'Album Demo');
      await tester.pumpAndSettle();

      // Verify only matching track is shown
      expect(find.text('Musique Demo 3'), findsOneWidget);
      expect(find.text('Exemple de Chanson 1'), findsNothing);
      expect(find.text('Chanson Test 2'), findsNothing);
    });

    testWidgets('should show empty state when no results found',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search for non-existent track
      await tester.enterText(find.byType(TextField), 'NonExistent');
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('Aucun résultat'), findsOneWidget);
      expect(find.textContaining('Aucune chanson ne correspond'), findsOneWidget);
    });

    testWidgets('should clear search when close icon is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Exemple');
      await tester.pumpAndSettle();

      // Verify filtered results
      expect(find.text('Exemple de Chanson 1'), findsOneWidget);
      expect(find.text('Chanson Test 2'), findsNothing);

      // Close search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify all tracks are shown again
      expect(find.text('Exemple de Chanson 1'), findsOneWidget);
      expect(find.text('Chanson Test 2'), findsOneWidget);
      expect(find.text('Musique Demo 3'), findsOneWidget);
      
      // Verify search field is hidden
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should perform case-insensitive search', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Search with lowercase for a title
      await tester.enterText(find.byType(TextField), 'demo');
      await tester.pumpAndSettle();

      // Verify matching track is found (case-insensitive)
      expect(find.text('Musique Demo 3'), findsOneWidget);
      expect(find.text('Exemple de Chanson 1'), findsNothing);
      expect(find.text('Chanson Test 2'), findsNothing);
    });

    testWidgets('should update results in real-time as user types',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryScreen(),
        ),
      );

      // Activate search
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Type partial query
      await tester.enterText(find.byType(TextField), 'Chan');
      await tester.pumpAndSettle();

      // Verify tracks with "Chan" in title are shown
      expect(find.text('Exemple de Chanson 1'), findsOneWidget);
      expect(find.text('Chanson Test 2'), findsOneWidget);
      expect(find.text('Musique Demo 3'), findsNothing);

      // Continue typing to narrow results
      await tester.enterText(find.byType(TextField), 'Chanson Test');
      await tester.pumpAndSettle();

      // Verify only one track matches now
      expect(find.text('Chanson Test 2'), findsOneWidget);
      expect(find.text('Exemple de Chanson 1'), findsNothing);
    });
  });
}
