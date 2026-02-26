import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Service for caching artwork images with LRU (Least Recently Used) eviction.
/// 
/// Features:
/// - In-memory LRU cache for fast access (max 100 images)
/// - Disk cache for additional storage
/// - Automatic cache cleanup when limits are exceeded
/// - Support for both local file URIs and network URLs
/// 
/// Requirements: 25.1, 25.2
class ArtworkCacheService {
  static final ArtworkCacheService _instance = ArtworkCacheService._internal();
  factory ArtworkCacheService() => _instance;
  ArtworkCacheService._internal();

  // In-memory LRU cache with max 100 entries
  static const int _maxMemoryCacheSize = 100;
  final Map<String, Uint8List> _memoryCache = {};
  final List<String> _lruKeys = [];

  // Disk cache directory
  Directory? _diskCacheDir;
  bool _initialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Get cache directory
      final cacheDir = await getTemporaryDirectory();
      _diskCacheDir = Directory(path.join(cacheDir.path, 'artwork_cache'));
      
      // Create directory if it doesn't exist
      if (!await _diskCacheDir!.exists()) {
        await _diskCacheDir!.create(recursive: true);
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize artwork cache: $e');
    }
  }

  /// Get cached artwork bytes from memory or disk
  Future<Uint8List?> getCachedArtwork(String key) async {
    if (!_initialized) await initialize();

    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      _updateLRU(key);
      return _memoryCache[key];
    }

    // Check disk cache
    if (_diskCacheDir != null) {
      final file = File(path.join(_diskCacheDir!.path, _sanitizeKey(key)));
      if (await file.exists()) {
        try {
          final bytes = await file.readAsBytes();
          // Add to memory cache
          _addToMemoryCache(key, bytes);
          return bytes;
        } catch (e) {
          debugPrint('Failed to read cached artwork: $e');
        }
      }
    }

    return null;
  }

  /// Cache artwork bytes in memory and disk
  Future<void> cacheArtwork(String key, Uint8List bytes) async {
    if (!_initialized) await initialize();

    // Add to memory cache
    _addToMemoryCache(key, bytes);

    // Save to disk cache
    if (_diskCacheDir != null) {
      try {
        final file = File(path.join(_diskCacheDir!.path, _sanitizeKey(key)));
        await file.writeAsBytes(bytes);
      } catch (e) {
        debugPrint('Failed to cache artwork to disk: $e');
      }
    }
  }

  /// Add item to memory cache with LRU eviction
  void _addToMemoryCache(String key, Uint8List bytes) {
    // If already in cache, update LRU
    if (_memoryCache.containsKey(key)) {
      _updateLRU(key);
      return;
    }

    // Evict oldest item if cache is full
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _lruKeys.removeAt(0);
      _memoryCache.remove(oldestKey);
    }

    // Add new item
    _memoryCache[key] = bytes;
    _lruKeys.add(key);
  }

  /// Update LRU order for a key
  void _updateLRU(String key) {
    _lruKeys.remove(key);
    _lruKeys.add(key);
  }

  /// Sanitize cache key to be filesystem-safe
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-.]'), '_');
  }

  /// Clear all caches
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    _lruKeys.clear();

    // Clear disk cache
    if (_diskCacheDir != null && await _diskCacheDir!.exists()) {
      try {
        await _diskCacheDir!.delete(recursive: true);
        await _diskCacheDir!.create(recursive: true);
      } catch (e) {
        debugPrint('Failed to clear disk cache: $e');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'maxMemoryCacheSize': _maxMemoryCacheSize,
      'diskCacheDir': _diskCacheDir?.path,
    };
  }
}
