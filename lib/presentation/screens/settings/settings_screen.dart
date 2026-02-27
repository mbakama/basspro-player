import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../providers/theme_provider.dart';
import '../../../domain/entities/eq_preset.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../data/repositories/eq_preset_repository_impl.dart';
import '../../../domain/repositories/eq_preset_repository.dart';
import '../../providers/scanner_provider.dart';
import '../../../data/services/library_scanner_service.dart';
import '../../../core/constants/app_colors.dart';

final eqPresetRepositoryProvider = Provider<EqPresetRepository>((ref) {
  return EqPresetRepositoryImpl(DatabaseService());
});

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
  
  Timer? _sleepTimerCountdown;
  DateTime? _sleepTimerEndTime;
  String? _sleepTimerRemaining;

  @override
  void initState() {
    super.initState();
    _loadPresets();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _sleepTimerCountdown?.cancel();
    super.dispose();
  }

  Future<void> _loadPresets() async {
    try {
      final repository = ref.read(eqPresetRepositoryProvider);
      final presets = await repository.getAllEqPresets();
      setState(() { _presets = presets; _isLoadingPresets = false; });
    } catch (e) {
      setState(() { _isLoadingPresets = false; });
    }
  }

  Future<void> _loadSettings() async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final keepAwake = await settingsRepo.getBoolSetting('keep_screen_awake', defaultValue: false);
    final sleepTimer = await settingsRepo.getSetting('sleep_timer') ?? 'Off';
    final defaultPreset = await settingsRepo.getSetting('default_eq_preset');
    
    setState(() {
      _keepScreenAwake = keepAwake;
      _sleepTimer = sleepTimer;
      _selectedPresetId = defaultPreset;
    });
    
    if (_keepScreenAwake) WakelockPlus.enable();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          _buildSectionHeader('GÉNÉRAL'),
          _buildSettingsTile(
            icon: Icons.refresh_rounded,
            title: 'Analyse de la bibliothèque',
            subtitle: 'Rechercher de nouveaux fichiers audio',
            onTap: _rescanLibrary,
          ),
          _buildSettingsTile(
            icon: Icons.timer_outlined,
            title: 'Minuterie de sommeil',
            subtitle: _sleepTimer == 'Off' ? 'Désactivée' : '$_sleepTimer minutes',
            onTap: () {}, // TODO: Sleep timer logic
          ),
          const Divider(height: 32, indent: 64),
          _buildSectionHeader('LECTURE'),
          _buildSettingsTile(
            icon: Icons.equalizer_rounded,
            title: 'Égaliseur par défaut',
            subtitle: _presets.isNotEmpty ? 'Configuration personnalisée' : 'Chargement...',
            onTap: () {}, 
          ),
          SwitchListTile(
            secondary: _buildIcon(Icons.screen_lock_portrait_rounded),
            title: const Text('Garder l\'écran allumé'),
            subtitle: const Text('Empêcher la mise en veille'),
            value: _keepScreenAwake,
            activeColor: AppColors.darkPrimary,
            onChanged: (v) {
              setState(() => _keepScreenAwake = v);
              if (v) WakelockPlus.enable(); else WakelockPlus.disable();
            },
          ),
          const Divider(height: 32, indent: 64),
          _buildSectionHeader('À PROPOS'),
          _buildSettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'BassPro Player',
            subtitle: 'Version 1.0.0 (Premium Build)',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: const TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: _buildIcon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white30)) : null,
      onTap: onTap,
    );
  }

  Widget _buildIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: Colors.white70, size: 20),
    );
  }

  Future<void> _rescanLibrary() async {
    final scannerService = ref.read(libraryScannerServiceProvider);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Analyse...'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            StreamBuilder<ScanProgress>(
              stream: scannerService.scanProgressStream,
              builder: (context, snapshot) {
                final message = snapshot.data?.message ?? 'Initialisation...';
                return Text(message, style: const TextStyle(fontSize: 12));
              },
            ),
          ],
        ),
      ),
    );

    try {
      await scannerService.scanLibrary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) Navigator.pop(context);
    }
  }
}
