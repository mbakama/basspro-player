import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/core/constants/asset_paths.dart';

void main() {
  group('AssetPaths', () {
    test('track placeholder path is correct', () {
      expect(AssetPaths.trackPlaceholder, 'assets/images/track_placeholder.png');
    });

    test('stream placeholder path is correct', () {
      expect(AssetPaths.streamPlaceholder, 'assets/images/stream_placeholder.png');
    });

    test('splash branding path is correct', () {
      expect(AssetPaths.splashBranding, 'assets/images/splash_branding.png');
    });

    test('app icon path is correct', () {
      expect(AssetPaths.appIcon, 'assets/icon/app_icon.png');
    });

    test('all paths use forward slashes', () {
      // Ensure paths work on all platforms
      expect(AssetPaths.trackPlaceholder.contains('\\'), false);
      expect(AssetPaths.streamPlaceholder.contains('\\'), false);
      expect(AssetPaths.splashBranding.contains('\\'), false);
      expect(AssetPaths.appIcon.contains('\\'), false);
    });

    test('all image paths start with assets/', () {
      expect(AssetPaths.trackPlaceholder.startsWith('assets/'), true);
      expect(AssetPaths.streamPlaceholder.startsWith('assets/'), true);
      expect(AssetPaths.splashBranding.startsWith('assets/'), true);
      expect(AssetPaths.appIcon.startsWith('assets/'), true);
    });
  });
}
