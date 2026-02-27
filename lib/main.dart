import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'data/datasources/database/database_service.dart';
import 'data/repositories/eq_preset_repository_impl.dart';
import 'data/services/app_initialization_service.dart';
import 'core/utils/logger.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/main_screen.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Preserve the splash screen until initialization is complete
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  // Start app initialization in background (non-blocking)
  // This allows the UI to display immediately while initialization continues
  _initializeAppAsync();

  runApp(const ProviderScope(child: BassProPlayerApp()));
}

/// Initialize the application asynchronously in the background.
///
/// This function handles startup initialization tasks without blocking the UI:
/// - Database initialization (critical - done first)
/// - Audio service initialization for background playback (critical)
/// - Built-in preset initialization is deferred (loaded lazily when needed)
///
/// The splash screen is displayed during initialization and removed when complete.
void _initializeAppAsync() {
  Future(() async {
    try {
      AppLoggers.app.info('Starting background initialization...');

      // Create database service instance
      final databaseService = DatabaseService();

      // Create equalizer preset repository
      final eqPresetRepository = EqPresetRepositoryImpl(databaseService);

      // Create and run initialization service
      // Note: Preset initialization is deferred to when equalizer is first opened
      final initService = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        deferPresetInitialization: true, // Defer non-critical initialization
      );

      // Add timeout to prevent hanging indefinitely
      final audioHandler = await initService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          AppLoggers.app.warning('Initialization timed out after 10 seconds');
          return null;
        },
      );

      if (audioHandler != null) {
        AppLoggers.app.info('BassPro Player initialized successfully');
        AppLoggers.app.info('Audio service ready for background playback');
      } else {
        AppLoggers.app.error('BassPro Player initialization failed');
      }
    } catch (e, stackTrace) {
      AppLoggers.app.error('Failed to initialize app', e, stackTrace);
      // Continue anyway - the app should still be usable
    } finally {
      // Remove splash screen after initialization (success or failure)
      FlutterNativeSplash.remove();
      AppLoggers.app.info('Splash screen removed');
    }
  });
}

class BassProPlayerApp extends ConsumerWidget {
  const BassProPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'BassPro Player',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainScreen(),
    );
  }
}
