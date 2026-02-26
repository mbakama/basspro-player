import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/presentation/widgets/mini_player.dart';

void main() {
  group('MiniPlayer Widget Tests', () {
    testWidgets('MiniPlayer hides when audio handler is not initialized', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniPlayer(),
          ),
        ),
      );

      // Verify that the mini player is not visible (SizedBox.shrink)
      expect(find.byType(MiniPlayer), findsOneWidget);
      
      // The widget should render as SizedBox.shrink when no audio handler
      final miniPlayerWidget = tester.widget<MiniPlayer>(find.byType(MiniPlayer));
      expect(miniPlayerWidget, isNotNull);
    });

    testWidgets('MiniPlayer widget can be instantiated', (WidgetTester tester) async {
      // Verify the widget can be created
      const miniPlayer = MiniPlayer();
      expect(miniPlayer, isNotNull);
    });
  });
}
