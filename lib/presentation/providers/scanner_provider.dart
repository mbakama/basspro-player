import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/library_scanner_service.dart';

/// Provider for LibraryScannerService
final libraryScannerServiceProvider = Provider<LibraryScannerService>((ref) {
  return LibraryScannerService();
});
