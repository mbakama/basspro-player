/// Asset path constants for BassPro Player
/// 
/// Centralized location for all asset paths used throughout the app.
/// This ensures consistency and makes it easy to update paths if needed.
class AssetPaths {
  // Private constructor to prevent instantiation
  AssetPaths._();

  /// Placeholder image for tracks without artwork
  /// 
  /// Use this when a track doesn't have embedded artwork or when
  /// artwork fails to load.
  /// 
  /// Example:
  /// ```dart
  /// Image.asset(
  ///   AssetPaths.trackPlaceholder,
  ///   width: 48,
  ///   height: 48,
  ///   fit: BoxFit.cover,
  /// )
  /// ```
  static const String trackPlaceholder = 'assets/images/track_placeholder.png';

  /// Placeholder image for streaming sources
  /// 
  /// Use this for stream sources that don't have custom artwork.
  /// 
  /// Example:
  /// ```dart
  /// Image.asset(
  ///   AssetPaths.streamPlaceholder,
  ///   width: 48,
  ///   height: 48,
  ///   fit: BoxFit.cover,
  /// )
  /// ```
  static const String streamPlaceholder = 'assets/images/stream_placeholder.png';

  /// Splash screen branding image
  /// 
  /// Used by flutter_native_splash for the splash screen.
  static const String splashBranding = 'assets/images/splash_branding.png';

  /// App icon
  /// 
  /// Used for launcher icon and splash screen.
  static const String appIcon = 'assets/icon/app_icon.png';
}
