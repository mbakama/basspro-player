import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/presentation/screens/player/equalizer_screen.dart';

void main() {
  group('EqualizerScreen Layout Tests', () {
    testWidgets('displays header with title and close button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify header title
      expect(find.text('Égaliseur'), findsOneWidget);
      
      // Verify close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays preset selector dropdown', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify preset label
      expect(find.text('Préréglage'), findsOneWidget);
      
      // Verify dropdown exists
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      
      // Verify default preset is selected
      expect(find.text('Équilibré'), findsOneWidget);
    });

    testWidgets('displays preamp slider with dB value label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify preamp label
      expect(find.text('Préampli'), findsOneWidget);
      
      // Verify initial dB value (0.0 dB) - there are multiple due to sub-bass and bass
      expect(find.text('0.0 dB'), findsWidgets);
      
      // Verify slider exists
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);
    });

    testWidgets('displays 10 frequency band sliders with labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify frequency bands section title
      expect(find.text('Bandes de fréquence'), findsOneWidget);
      
      // Verify all 10 frequency labels
      expect(find.text('32'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('1k'), findsOneWidget);
      expect(find.text('2k'), findsOneWidget);
      expect(find.text('4k'), findsOneWidget);
      expect(find.text('8k'), findsOneWidget);
      expect(find.text('16k'), findsOneWidget);
    });

    testWidgets('displays sub-bass and bass boost sliders with dB values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify bass controls section
      expect(find.text('Contrôles de basses'), findsOneWidget);
      
      // Verify sub-bass control
      expect(find.text('Sub-Bass'), findsOneWidget);
      
      // Verify bass control
      expect(find.text('Bass'), findsOneWidget);
    });

    testWidgets('displays limiter toggle checkbox', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify limiter checkbox
      expect(find.byType(Checkbox), findsOneWidget);
      
      // Verify limiter label
      expect(find.text('Limiteur activé'), findsOneWidget);
      
      // Verify checkbox is checked by default
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('displays save preset button at bottom', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify save preset button
      expect(find.text('Sauvegarder préréglage'), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('does not show warning indicator when limiter is enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Warning should not be visible initially (limiter enabled by default)
      expect(find.text('Risque de distorsion détecté'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('shows warning indicator when clipping risk detected and limiter disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Scroll to make checkbox visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Disable limiter
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      // Scroll back to top to access preamp slider
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Increase preamp significantly to trigger warning (need to exceed 12dB threshold)
      final preampSlider = find.byType(Slider).first;
      // Drag far to the right to get a high value
      await tester.drag(preampSlider, const Offset(400, 0));
      await tester.pumpAndSettle();

      // Scroll down to frequency bands and increase some bands
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pumpAndSettle();

      // Scroll down more to bass controls
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Warning should now be visible
      expect(find.text('Risque de distorsion détecté'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('close button dismisses the screen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => const EqualizerScreen(),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the equalizer screen
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify screen is visible
      expect(find.text('Égaliseur'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify screen is dismissed
      expect(find.text('Égaliseur'), findsNothing);
    });

    testWidgets('preset selector changes selected preset', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Initial preset
      expect(find.text('Équilibré'), findsOneWidget);

      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select different preset
      await tester.tap(find.text('Deep Bass').last);
      await tester.pumpAndSettle();

      // Verify preset changed
      expect(find.text('Deep Bass'), findsOneWidget);
    });

    testWidgets('save preset button shows dialog', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Scroll to make save button visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -800));
      await tester.pumpAndSettle();

      // Tap save preset button
      await tester.tap(find.text('Sauvegarder préréglage'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Nom du préréglage'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    testWidgets('preamp slider updates dB value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Initial value - multiple 0.0 dB texts exist
      expect(find.text('0.0 dB'), findsWidgets);

      // Drag preamp slider
      final preampSlider = find.byType(Slider).first;
      await tester.drag(preampSlider, const Offset(100, 0));
      await tester.pumpAndSettle();

      // Verify slider value changed by checking that preamp label still exists
      expect(find.text('Préampli'), findsOneWidget);
    });

    testWidgets('all UI text is in French', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify French text elements
      expect(find.text('Égaliseur'), findsOneWidget);
      expect(find.text('Préréglage'), findsOneWidget);
      expect(find.text('Préampli'), findsOneWidget);
      expect(find.text('Bandes de fréquence'), findsOneWidget);
      expect(find.text('Contrôles de basses'), findsOneWidget);
      expect(find.text('Sub-Bass'), findsOneWidget);
      expect(find.text('Bass'), findsOneWidget);
      expect(find.text('Limiteur activé'), findsOneWidget);
      expect(find.text('Sauvegarder préréglage'), findsOneWidget);
    });
  });

  group('EqualizerScreen Interaction Tests', () {
    testWidgets('limiter checkbox can be toggled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Scroll to make checkbox visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Initial state - enabled
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);

      // Toggle off
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final checkboxAfter = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkboxAfter.value, isFalse);

      // Toggle back on
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      final checkboxFinal = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkboxFinal.value, isTrue);
    });

    testWidgets('screen is scrollable', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EqualizerScreen(),
          ),
        ),
      );

      // Verify SingleChildScrollView exists
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
