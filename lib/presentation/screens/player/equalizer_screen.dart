import 'package:flutter/material.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../data/services/audio/basspro_audio_handler.dart';
import '../../../data/services/equalizer_service.dart';
import '../../../domain/entities/eq_preset.dart';
import '../../../data/repositories/eq_preset_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';
import '../../../core/constants/app_colors.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  EqualizerService? _equalizerService;
  List<EqPreset> _presets = [];
  EqPreset? _selectedPreset;
  
  double _preamp = 0.0;
  final List<double> _bandLevels = List.filled(10, 0.0);
  double _subBass = 0.0;
  double _bass = 0.0;
  bool _limiterEnabled = true;
  bool _showClippingWarning = false;
  bool _isLoading = true;

  final List<String> _frequencyLabels = ['32', '64', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];

  @override
  void initState() {
    super.initState();
    _initializeEqualizer();
  }

  Future<void> _initializeEqualizer() async {
    try {
      // Attendre que l'AudioService soit disponible avec timeout
      BassProAudioHandler? audioHandler;
      int attempts = 0;
      const maxAttempts = 40; // 40 tentatives max (20 secondes)
      
      while (attempts < maxAttempts) {
        audioHandler = AudioServiceInitializer.audioHandler;
        if (audioHandler != null) break;
        
        attempts++;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (audioHandler == null) {
        // Tenter de réinitialiser l'AudioService
        try {
          audioHandler = await AudioServiceInitializer.forceReinitialize();
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          throw Exception('Audio service non disponible après tentative de réinitialisation: $e');
        }
      }
      
      _equalizerService = audioHandler.equalizerService;

      final databaseService = DatabaseService();
      final presetRepo = EqPresetRepositoryImpl(databaseService);
      await presetRepo.initializeBuiltinPresets();
      final presets = await presetRepo.getAllEqPresets();
      final service = _equalizerService!;
      
      setState(() {
        _presets = presets;
        _preamp = service.preamp;
        _bandLevels.setAll(0, service.bandLevels);
        _subBass = service.subBass;
        _bass = service.bass;
        _limiterEnabled = service.limiterEnabled;
        _showClippingWarning = service.isClippingRisk();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Égaliseur indisponible: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Initialisation de l\'égaliseur...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (_equalizerService == null) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Égaliseur indisponible',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Veuillez redémarrer l\'application',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildPresetSelector(),
                  const SizedBox(height: 24),
                  _buildPreampControl(),
                  const SizedBox(height: 32),
                  _buildFrequencyBands(),
                  const SizedBox(height: 32),
                  _buildBassBoostControls(),
                  const SizedBox(height: 32),
                  _buildLimiterToggle(),
                  if (_showClippingWarning) _buildClippingWarning(),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40, height: 4,
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('ÉGALISEUR', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18)),
          TextButton.icon(
            onPressed: _showSavePresetDialog,
            icon: const Icon(Icons.save_rounded, size: 20),
            label: const Text('Sauver'),
            style: TextButton.styleFrom(foregroundColor: AppColors.darkPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(12)),
      child: DropdownButton<EqPreset?>(
        value: _selectedPreset,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: AppColors.darkSurface,
        hint: const Text('Préréglages'),
        items: [
          const DropdownMenuItem<EqPreset?>(value: null, child: Text('Personnalisé')),
          ..._presets.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
        ],
        onChanged: (p) async {
          if (p != null && _equalizerService != null) {
            await _equalizerService!.applyPreset(p);
            setState(() {
              _selectedPreset = p;
              _preamp = _equalizerService!.preamp;
              _bandLevels.setAll(0, _equalizerService!.bandLevels);
              _subBass = _equalizerService!.subBass;
              _bass = _equalizerService!.bass;
              _showClippingWarning = _equalizerService!.isClippingRisk();
            });
          }
        },
      ),
    );
  }

  Widget _buildPreampControl() {
    return _buildSliderRow('PREAMP', _preamp, -10, 10, (v) {
      setState(() { _preamp = v; _selectedPreset = null; });
      _equalizerService?.setPreamp(v);
    });
  }

  Widget _buildFrequencyBands() {
    return Column(
      children: [
        const Text('FRÉQUENCES', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white38)),
        const SizedBox(height: 24),
        SizedBox(
          height: 180,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (i) => _buildVerticalBand(i)),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalBand(int index) {
    return Column(
      children: [
        Text(_bandLevels[index].toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppColors.darkPrimary)),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              activeTrackColor: AppColors.darkPrimary,
              inactiveTrackColor: Colors.white10,
            ),
            child: RotatedBox(
              quarterTurns: 3,
              child: Slider(
                value: _bandLevels[index],
                min: -15, max: 15,
                onChanged: (v) {
                  setState(() { _bandLevels[index] = v; _selectedPreset = null; });
                  _equalizerService?.setBandLevel(index, v);
                },
              ),
            ),
          ),
        ),
        Text(_frequencyLabels[index], style: const TextStyle(fontSize: 10, color: Colors.white24)),
      ],
    );
  }

  Widget _buildBassBoostControls() {
    return Row(
      children: [
        Expanded(child: _buildSmallSlider('SUB-BASS', _subBass, 0, 12, (v) {
          setState(() { _subBass = v; _selectedPreset = null; });
          _equalizerService?.setSubBass(v);
          setState(() => _bandLevels.setAll(0, _equalizerService!.bandLevels));
        })),
        const SizedBox(width: 16),
        Expanded(child: _buildSmallSlider('BASS', _bass, 0, 12, (v) {
          setState(() { _bass = v; _selectedPreset = null; });
          _equalizerService?.setBass(v);
          setState(() => _bandLevels.setAll(0, _equalizerService!.bandLevels));
        })),
      ],
    );
  }

  Widget _buildSmallSlider(String label, double val, double min, double max, ValueChanged<double> onChg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white30)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
          child: Slider(value: val, min: min, max: max, activeColor: AppColors.darkSecondary, onChanged: onChg),
        ),
      ],
    );
  }

  Widget _buildSliderRow(String label, double val, double min, double max, ValueChanged<double> onChg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white54)),
            Text('${val.toStringAsFixed(1)} dB', style: const TextStyle(color: AppColors.darkPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: val, min: min, max: max, activeColor: AppColors.darkPrimary, onChanged: onChg),
      ],
    );
  }

  Widget _buildLimiterToggle() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Limiteur Active', style: TextStyle(fontSize: 14)),
      subtitle: const Text('Protection contre la saturation', style: TextStyle(fontSize: 12, color: Colors.white30)),
      activeThumbColor: AppColors.darkPrimary,
      value: _limiterEnabled,
      onChanged: (v) {
        setState(() => _limiterEnabled = v);
        _equalizerService?.setLimiterEnabled(v);
      },
    );
  }

  Widget _buildClippingWarning() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Expanded(child: Text('Saturation détectée ! Réduisez le preamp.', style: TextStyle(color: Colors.red, fontSize: 13))),
        ],
      ),
    );
  }

  void _showSavePresetDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nom du préréglage'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('ANNULER')),
          TextButton(onPressed: () async {
            if (controller.text.isEmpty) return;
            if (!context.mounted) return;
            final p = EqPreset(name: controller.text, bandLevels: List.from(_bandLevels), preamp: _preamp, subBass: _subBass, bass: _bass, limiterEnabled: _limiterEnabled, createdAt: DateTime.now(), isBuiltin: false);
            await EqPresetRepositoryImpl(DatabaseService()).insertEqPreset(p);
            if (context.mounted) Navigator.pop(c);
          }, child: const Text('SAUVER')),
        ],
      ),
    );
  }
}
