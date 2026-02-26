import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/presentation/widgets/artwork_image.dart';
import 'package:basspro_player/core/constants/asset_paths.dart';

void main() {
  group('ArtworkImage', () {
    testWidgets('displays track placeholder when artworkUri is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtworkImage.track(
              artworkUri: null,
              width: 48,
              height: 48,
            ),
          ),
        ),
      );

      // Should display the track placeholder
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, AssetPaths.trackPlaceholder);
    });

    testWidgets('displays stream placeholder when isStream is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtworkImage.stream(
              artworkUri: null,
              width: 48,
              height: 48,
            ),
          ),
        ),
      );

      // Should display the stream placeholder
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final image = tester.widget<Image>(imageFinder);
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, AssetPaths.streamPlaceholder);
    });

    testWidgets('applies correct dimensions', (tester) async {
      const testWidth = 100.0;
      const testHeight = 100.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtworkImage.track(
              artworkUri: null,
              width: testWidth,
              height: testHeight,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.width, testWidth);
      expect(image.height, testHeight);
    });

    testWidgets('applies border radius', (tester) async {
      const testRadius = 12.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtworkImage.track(
              artworkUri: null,
              width: 48,
              height: 48,
              borderRadius: testRadius,
            ),
          ),
        ),
      );

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      final borderRadius = clipRRect.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, testRadius);
    });

    testWidgets('applies BoxFit correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtworkImage.track(
              artworkUri: null,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
    });
  });

  group('PlaceholderImage extension', () {
    testWidgets('trackPlaceholder creates correct image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceholderImage.trackPlaceholder(
              width: 48,
              height: 48,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, AssetPaths.trackPlaceholder);
      expect(image.width, 48);
      expect(image.height, 48);
    });

    testWidgets('streamPlaceholder creates correct image', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlaceholderImage.streamPlaceholder(
              width: 48,
              height: 48,
            ),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      final assetImage = image.image as AssetImage;
      expect(assetImage.assetName, AssetPaths.streamPlaceholder);
      expect(image.width, 48);
      expect(image.height, 48);
    });
  });
}
