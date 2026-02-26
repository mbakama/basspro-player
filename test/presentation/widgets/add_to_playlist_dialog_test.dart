import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/presentation/widgets/add_to_playlist_dialog.dart';
import 'package:basspro_player/domain/entities/track.dart';

void main() {
  group('AddToPlaylistDialog', () {
    late Track testTrack;

    setUp(() {
      testTrack = Track(
        id: 1,
        title: 'Test Track',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: const Duration(minutes: 3, seconds: 30),
        uri: 'content://media/external/audio/media/1',
        dateAdded: DateTime.now(),
      );
    });

    testWidgets('displays dialog title', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AddToPlaylistDialog(track: testTrack),
            ),
          ),
        ),
      );

      expect(find.text('Ajouter à la playlist'), findsOneWidget);
    });

    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AddToPlaylistDialog(track: testTrack),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays cancel and add buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => AddToPlaylistDialog(track: testTrack),
            ),
          ),
        ),
      );

      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Ajouter'), findsOneWidget);
    });

    testWidgets('cancel button closes dialog', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddToPlaylistDialog(track: testTrack),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is open
      expect(find.text('Ajouter à la playlist'), findsOneWidget);

      // Tap cancel button
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Ajouter à la playlist'), findsNothing);
    });
  });
}
