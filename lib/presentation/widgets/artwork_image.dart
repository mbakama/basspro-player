import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/asset_paths.dart';

/// Widget that displays artwork with automatic fallback to placeholder
/// 
/// Handles three scenarios:
/// 1. Valid artwork URI - displays the artwork
/// 2. Invalid/missing artwork - displays placeholder
/// 3. Loading error - displays placeholder
/// 
/// Supports both track artwork and stream source artwork.
class ArtworkImage extends StatelessWidget {
  /// URI of the artwork (can be null)
  final String? artworkUri;

  /// Width of the image
  final double width;

  /// Height of the image
  final double height;

  /// How the image should fit within its bounds
  final BoxFit fit;

  /// Border radius for rounded corners
  final double borderRadius;

  /// Whether this is for a stream source (uses different placeholder)
  final bool isStream;

  const ArtworkImage({
    super.key,
    this.artworkUri,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0,
    this.isStream = false,
  });

  /// Factory constructor for track artwork
  factory ArtworkImage.track({
    required String? artworkUri,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 8.0,
  }) {
    return ArtworkImage(
      artworkUri: artworkUri,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      isStream: false,
    );
  }

  /// Factory constructor for stream source artwork
  factory ArtworkImage.stream({
    required String? artworkUri,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 8.0,
  }) {
    return ArtworkImage(
      artworkUri: artworkUri,
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      isStream: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    // If no artwork URI, show placeholder immediately
    if (artworkUri == null || artworkUri!.isEmpty) {
      return _buildPlaceholder();
    }

    // Try to load the artwork, with placeholder as fallback
    return Image.file(
      File(artworkUri!),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // If loading fails, show placeholder
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    final placeholderPath = isStream 
        ? AssetPaths.streamPlaceholder 
        : AssetPaths.trackPlaceholder;

    return Image.asset(
      placeholderPath,
      width: width,
      height: height,
      fit: fit,
    );
  }
}

/// Extension on Image.asset for easier placeholder usage
extension PlaceholderImage on Image {
  /// Create a track placeholder image
  static Image trackPlaceholder({
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      AssetPaths.trackPlaceholder,
      width: width,
      height: height,
      fit: fit,
    );
  }

  /// Create a stream placeholder image
  static Image streamPlaceholder({
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    return Image.asset(
      AssetPaths.streamPlaceholder,
      width: width,
      height: height,
      fit: fit,
    );
  }
}
