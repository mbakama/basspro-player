import 'package:flutter_test/flutter_test.dart';
import 'package:basspro_player/data/services/app_initialization_service.dart';
import 'package:basspro_player/data/datasources/database/database_service.dart';
import 'package:basspro_player/data/repositories/eq_preset_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService databaseService;
  late EqPresetRepositoryImpl eqPresetRepository;
  late AppInitializationService initService;

  // Initialize sqflite for testing
  setUpAll(() {
    // Initialize ffi implementation for testing
    sqfliteFfiInit();
    // Set the database factory for testing
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Initialize test database
    databaseService = DatabaseService();
    
    // Delete any existing test database
    try {
      await databaseService.deleteDatabase();
    } catch (e) {
      // Ignore if database doesn't exist
    }
    
    // Create repository
    eqPresetRepository = EqPresetRepositoryImpl(databaseService);
    
    // Create initialization service
    initService = AppInitializationService(
      databaseService: databaseService,
      eqPresetRepository: eqPresetRepository,
      initializeAudio: false, // Disable audio initialization in tests
    );
  });

  tearDown(() async {
    // Clean up database after each test
    await databaseService.close();
    try {
      await databaseService.deleteDatabase();
    } catch (e) {
      // Ignore cleanup errors
    }
  });

  group('AppInitializationService', () {
    test('initialize() should complete successfully', () async {
      final result = await initService.initialize();
      // In test mode with audio disabled, result will be null but initialization should succeed
      expect(result, isNull);
    });

    test('initialize() should create all 8 built-in presets', () async {
      // Create initialization service with preset initialization enabled
      final initServiceWithPresets = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        initializeAudio: false,
        deferPresetInitialization: false, // Enable preset initialization for this test
      );
      
      // Initialize the app
      await initServiceWithPresets.initialize();

      // Get all presets from database
      final allPresets = await eqPresetRepository.getAllEqPresets();

      // Should have exactly 8 built-in presets
      expect(allPresets.length, equals(8));

      // Verify all presets are marked as built-in
      for (final preset in allPresets) {
        expect(preset.isBuiltin, isTrue);
      }
    });

    test('initialize() should create presets with correct names', () async {
      // Create initialization service with preset initialization enabled
      final initServiceWithPresets = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        initializeAudio: false,
        deferPresetInitialization: false,
      );
      
      // Initialize the app
      await initServiceWithPresets.initialize();

      // Get all presets from database
      final allPresets = await eqPresetRepository.getAllEqPresets();

      // Expected preset names
      final expectedNames = [
        'Deep Bass',
        'Punch Bass',
        'Hip-Hop',
        'EDM',
        'Rock',
        'Pop',
        'Vocal Clarity',
        'Balanced',
      ];

      // Extract preset names
      final actualNames = allPresets.map((p) => p.name).toList();

      // Verify all expected names are present
      for (final name in expectedNames) {
        expect(actualNames, contains(name));
      }
    });

    test('initialize() should not duplicate presets on multiple calls', () async {
      // Create initialization service with preset initialization enabled
      final initServiceWithPresets = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        initializeAudio: false,
        deferPresetInitialization: false,
      );
      
      // Initialize the app twice
      await initServiceWithPresets.initialize();
      await initServiceWithPresets.initialize();

      // Get all presets from database
      final allPresets = await eqPresetRepository.getAllEqPresets();

      // Should still have exactly 8 presets (no duplicates)
      expect(allPresets.length, equals(8));
    });

    test('built-in presets should have correct structure', () async {
      // Create initialization service with preset initialization enabled
      final initServiceWithPresets = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        initializeAudio: false,
        deferPresetInitialization: false,
      );
      
      // Initialize the app
      await initServiceWithPresets.initialize();

      // Get all presets from database
      final allPresets = await eqPresetRepository.getAllEqPresets();

      // Verify each preset has the correct structure
      for (final preset in allPresets) {
        // Should have 10 band levels
        expect(preset.bandLevels.length, equals(10));

        // Should have preamp value
        expect(preset.preamp, isNotNull);

        // Should have sub-bass value
        expect(preset.subBass, isNotNull);

        // Should have bass value
        expect(preset.bass, isNotNull);

        // Limiter should be enabled by default
        expect(preset.limiterEnabled, isTrue);

        // Should be marked as built-in
        expect(preset.isBuiltin, isTrue);
      }
    });

    test('Deep Bass preset should have correct values', () async {
      // Create initialization service with preset initialization enabled
      final initServiceWithPresets = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        initializeAudio: false,
        deferPresetInitialization: false,
      );
      
      // Initialize the app
      await initServiceWithPresets.initialize();

      // Get Deep Bass preset
      final deepBass = await eqPresetRepository.getEqPresetByName('Deep Bass');

      expect(deepBass, isNotNull);
      expect(deepBass!.name, equals('Deep Bass'));
      expect(deepBass.bandLevels, equals([8.0, 6.0, 4.0, 2.0, 0.0, -1.0, -2.0, -2.0, -2.0, -2.0]));
      expect(deepBass.preamp, equals(-3.0));
      expect(deepBass.subBass, equals(8.0));
      expect(deepBass.bass, equals(6.0));
      expect(deepBass.limiterEnabled, isTrue);
      expect(deepBass.isBuiltin, isTrue);
    });

    test('Balanced preset should have all zero values', () async {
      // Create initialization service with preset initialization enabled
      final initServiceWithPresets = AppInitializationService(
        databaseService: databaseService,
        eqPresetRepository: eqPresetRepository,
        initializeAudio: false,
        deferPresetInitialization: false,
      );
      
      // Initialize the app
      await initServiceWithPresets.initialize();

      // Get Balanced preset
      final balanced = await eqPresetRepository.getEqPresetByName('Balanced');

      expect(balanced, isNotNull);
      expect(balanced!.name, equals('Balanced'));
      expect(balanced.bandLevels, equals([0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]));
      expect(balanced.preamp, equals(0.0));
      expect(balanced.subBass, equals(0.0));
      expect(balanced.bass, equals(0.0));
      expect(balanced.limiterEnabled, isTrue);
      expect(balanced.isBuiltin, isTrue);
    });
  });
}
