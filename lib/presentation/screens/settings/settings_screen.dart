import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/theme_provider.dart';
import '../../../domain/entities/eq_preset.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../data/repositories/eq_preset_repository_impl.dart';
import '../../../domain/repositories/eq_preset_repository.dart';
import '../../../data/services/library_scanner_service.dart';
import '../../../data/services/audio/audio_service_initializer.dart';

/// Provider for EqPresetRepository
final eqPresetRepositoryProvider = Provider<EqPresetRepository>((ref) {
  return EqPresetRepositoryImpl(DatabaseService());
});

/// Provider for LibraryScannerService
final libraryScannerServiceProvider = Provider<LibraryScannerService>((ref) {
  return LibraryScannerService();
});

/// Settings screen with app configuration options.
/// 
/// Provides settings for:
/// - Appearance (theme selection)
/// - Library (rescan button)
/// - Playback (default equalizer preset, keep screen awake)
/// - Sleep timer
/// - App information (version)
/// 
/// Requirements: 20.1, 20.2
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<EqPreset> _presets = [];
  String? _selectedPresetId;
  bool _keepScreenAwake = false;
  String _sleepTimer = 'Off';
  bool _isLoadingPresets = true;
  
  // Sleep timer state
  Timer? _sleepTimerCountdown;
  DateTime? _sleepTimerEndTime;
  String? _sleepTimerRemaining;
  
  // Library scanner subscription
  StreamSubscription<ScanProgress>? _scanProgressSubscription;

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _sleepTimerCountdown?.cancel();
    _scanProgressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    try {
      final repository = ref.read(eqPresetRepositoryProvider);
      final presets = await repository.getAllEqPresets();
      setState(() {
        _presets = presets;
        _isLoadingPresets = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPresets = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    
    // Load keep screen awake setting
    final keepAwake = await settingsRepo.getBoolSetting('keep_screen_awake', defaultValue: false);
    
    // Load sleep timer setting
    final sleepTimer = await settingsRepo.getSetting('sleep_timer') ?? 'Off';
    
    // Load default preset setting
    final defaultPreset = await settingsRepo.getSetting('default_eq_preset');
    
    // Load sleep timer end time if active
    final sleepTimerEndTimeStr = await settingsRepo.getSetting('sleep_timer_end_time');
    DateTime? sleepTimerEndTime;
    if (sleepTimerEndTimeStr != null) {
      sleepTimerEndTime = DateTime.tryParse(sleepTimerEndTimeStr);
      // Check if timer is still valid
      if (sleepTimerEndTime != null && sleepTimerEndTime.isAfter(DateTime.now())) {
        _startSleepTimerCountdown(sleepTimerEndTime);
      } else {
        // Timer expired, clear it
        await settingsRepo.setSetting('sleep_timer_end_time', '');
        sleepTimerEndTime = null;
      }
    }
    
    setState(() {
      _keepScreenAwake = keepAwake;
      _sleepTimer = sleepTimer;
      _selectedPresetId = defaultPreset;
      _sleepTimerEndTime = sleepTimerEndTime;
    });
    
    // Apply keep screen awake setting
    if (_keepScreenAwake) {
      WakelockPlus.enable();
    }
  }

  Future<void> _saveKeepScreenAwake(bool value) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setBoolSetting('keep_screen_awake', value);
    setState(() {
      _keepScreenAwake = value;
    });
    
    // Apply wakelock setting
    if (value) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  Future<void> _saveSleepTimer(String value) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setSetting('sleep_timer', value);
    
    // Cancel existing timer
    _sleepTimerCountdown?.cancel();
    _sleepTimerCountdown = null;
    _sleepTimerEndTime = null;
    _sleepTimerRemaining = null;
    
    if (value != 'Off') {
      // Start new timer
      final minutes = int.parse(value);
      final endTime = DateTime.now().add(Duration(minutes: minutes));
      
      // Save end time to persist across app restarts
      await settingsRepo.setSetting('sleep_timer_end_time', endTime.toIso8601String());
      
      _startSleepTimerCountdown(endTime);
    } else {
      // Clear saved end time
      await settingsRepo.setSetting('sleep_timer_end_time', '');
    }
    
    setState(() {
      _sleepTimer = value;
    });
  }
  
  void _startSleepTimerCountdown(DateTime endTime) {
    _sleepTimerEndTime = endTime;
    
    // Update remaining time immediately
    _updateSleepTimerRemaining();
    
    // Start countdown timer that updates every second
    _sleepTimerCountdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSleepTimerRemaining();
      
      // Check if timer expired
      if (DateTime.now().isAfter(endTime)) {
        timer.cancel();
        _onSleepTimerExpired();
      }
    });
  }
  
  void _updateSleepTimerRemaining() {
    if (_sleepTimerEndTime == null) return;
    
    final remaining = _sleepTimerEndTime!.difference(DateTime.now());
    
    if (remaining.isNegative) {
      setState(() {
        _sleepTimerRemaining = null;
      });
      return;
    }
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final seconds = remaining.inSeconds.remainder(60);
    
    setState(() {
      if (hours > 0) {
        _sleepTimerRemaining = '${hours}h ${minutes}m ${seconds}s';
      } else if (minutes > 0) {
        _sleepTimerRemaining = '${minutes}m ${seconds}s';
      } else {
        _sleepTimerRemaining = '${seconds}s';
      }
    });
  }
  
  Future<void> _onSleepTimerExpired() async {
    // Pause playback
    final audioHandler = AudioServiceInitializer.audioHandler;
    if (audioHandler != null) {
      await audioHandler.pause();
    }
    
    // Clear timer state
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setSetting('sleep_timer', 'Off');
    await settingsRepo.setSetting('sleep_timer_end_time', '');
    
    setState(() {
      _sleepTimer = 'Off';
      _sleepTimerEndTime = null;
      _sleepTimerRemaining = null;
    });
    
    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minuterie de sommeil expirée - Lecture en pause')),
      );
    }
  }

  Future<void> _saveDefaultPreset(String? presetId) async {
    if (presetId == null) return;
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setSetting('default_eq_preset', presetId);
    setState(() {
      _selectedPresetId = presetId;
    });
  }

  Future<void> _rescanLibrary() async {
    final scannerService = ref.read(libraryScannerServiceProvider);
    
    // Show progress dialog
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ScanProgressDialog(
        scannerService: scannerService,
      ),
    );
    
    try {
      // Start scanning
      final result = await scannerService.scanLibrary();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Analyse terminée: ${result.tracksFound} pistes trouvées, '
              '${result.tracksAdded} ajoutées, ${result.tracksRemoved} supprimées',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'analyse: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final currentThemeMode = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // Appearance Section
          _buildSectionHeader('Apparence', Icons.palette),
          _buildThemeSelector(currentThemeMode, themeNotifier),
          const Divider(),

          // Library Section
          _buildSectionHeader('Bibliothèque', Icons.library_music),
          _buildRescanButton(),
          const Divider(),

          // Playback Section
          _buildSectionHeader('Lecture', Icons.play_circle_outline),
          _buildDefaultPresetSelector(),
          _buildKeepScreenAwakeToggle(),
          _buildSleepTimerSelector(),
          const Divider(),

          // About Section
          _buildSectionHeader('À propos', Icons.info_outline),
          _buildAppVersion(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(ThemeMode currentMode, ThemeNotifier notifier) {
    return ListTile(
      leading: Icon(
        currentMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
      ),
      title: const Text('Thème'),
      subtitle: Text(currentMode == ThemeMode.dark ? 'Sombre' : 'Clair'),
      trailing: Switch(
        value: currentMode == ThemeMode.dark,
        onChanged: (value) {
          notifier.toggleTheme();
        },
      ),
      onTap: () {
        notifier.toggleTheme();
      },
    );
  }

  Widget _buildRescanButton() {
    return ListTile(
      leading: const Icon(Icons.refresh),
      title: const Text('Rescanner la bibliothèque'),
      subtitle: const Text('Rechercher de nouveaux fichiers audio'),
      trailing: const Icon(Icons.chevron_right),
      onTap: _rescanLibrary,
    );
  }

  Widget _buildDefaultPresetSelector() {
    if (_isLoadingPresets) {
      return const ListTile(
        leading: Icon(Icons.equalizer),
        title: Text('Égaliseur par défaut'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.equalizer),
      title: const Text('Égaliseur par défaut'),
      subtitle: Text(
        _selectedPresetId != null
            ? _presets.firstWhere(
                (p) => p.id.toString() == _selectedPresetId,
                orElse: () => _presets.first,
              ).name
            : 'Aucun',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showPresetSelector();
      },
    );
  }

  void _showPresetSelector() {
    String? selectedValue = _selectedPresetId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Égaliseur par défaut'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: selectedValue,
            onChanged: (value) {
              if (value != null) {
                _saveDefaultPreset(value);
                Navigator.of(context).pop();
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final preset = _presets[index];
                final isSelected = preset.id.toString() == selectedValue;
                
                return RadioListTile<String>(
                  title: Text(preset.name),
                  value: preset.id.toString(),
                  selected: isSelected,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeepScreenAwakeToggle() {
    return SwitchListTile(
      secondary: const Icon(Icons.screen_lock_portrait),
      title: const Text('Garder l\'écran allumé'),
      subtitle: const Text('Empêcher la mise en veille pendant la lecture'),
      value: _keepScreenAwake,
      onChanged: _saveKeepScreenAwake,
    );
  }

  Widget _buildSleepTimerSelector() {
    final options = ['Off', '15', '30', '45', '60', '90'];
    
    // Show remaining time if timer is active
    String subtitle;
    if (_sleepTimerRemaining != null) {
      subtitle = 'Temps restant: $_sleepTimerRemaining';
    } else if (_sleepTimer == 'Off') {
      subtitle = 'Désactivée';
    } else {
      subtitle = '$_sleepTimer minutes';
    }
    
    return ListTile(
      leading: const Icon(Icons.timer),
      title: const Text('Minuterie de sommeil'),
      subtitle: Text(subtitle),
      trailing: _sleepTimerRemaining != null
          ? IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _saveSleepTimer('Off'),
              tooltip: 'Annuler la minuterie',
            )
          : const Icon(Icons.chevron_right),
      onTap: () {
        _showSleepTimerSelector(options);
      },
    );
  }

  void _showSleepTimerSelector(List<String> options) {
    String selectedValue = _sleepTimer;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Minuterie de sommeil'),
        content: SizedBox(
          width: double.maxFinite,
          child: RadioGroup<String>(
            groupValue: selectedValue,
            onChanged: (value) {
              if (value != null) {
                _saveSleepTimer(value);
                Navigator.of(context).pop();
              }
            },
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = option == selectedValue;
                
                return RadioListTile<String>(
                  title: Text(
                    option == 'Off' 
                        ? 'Désactivée' 
                        : '$option minutes',
                  ),
                  value: option,
                  selected: isSelected,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppVersion() {
    return const ListTile(
      leading: Icon(Icons.info),
      title: Text('Version'),
      subtitle: Text('1.0.0'),
    );
  }
}

/// Dialog that displays library scan progress
class _ScanProgressDialog extends StatefulWidget {
  final LibraryScannerService scannerService;
  
  const _ScanProgressDialog({
    required this.scannerService,
  });
  
  @override
  State<_ScanProgressDialog> createState() => _ScanProgressDialogState();
}

class _ScanProgressDialogState extends State<_ScanProgressDialog> {
  ScanProgress? _currentProgress;
  StreamSubscription<ScanProgress>? _subscription;
  
  @override
  void initState() {
    super.initState();
    _subscription = widget.scannerService.scanProgressStream.listen((progress) {
      setState(() {
        _currentProgress = progress;
      });
    });
  }
  
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Analyse de la bibliothèque'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentProgress?.progress != null)
            LinearProgressIndicator(value: _currentProgress!.progress)
          else
            const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _currentProgress?.message ?? 'Initialisation...',
            textAlign: TextAlign.center,
          ),
          if (_currentProgress?.tracksFound != null) ...[
            const SizedBox(height: 8),
            Text(
              'Pistes trouvées: ${_currentProgress!.tracksFound}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_currentProgress?.tracksAdded != null) ...[
            Text(
              'Pistes ajoutées: ${_currentProgress!.tracksAdded}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
