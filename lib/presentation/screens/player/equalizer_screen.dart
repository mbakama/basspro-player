import 'package:flutter/material.dart';
import '../../../data/services/audio/audio_service_initializer.dart';
import '../../../data/services/equalizer_service.dart';
import '../../../domain/entities/eq_preset.dart';
import '../../../data/repositories/eq_preset_repository_impl.dart';
import '../../../data/datasources/database/database_service.dart';

/// Equalizer screen displayed as a modal bottom sheet
///
/// This screen provides professional-grade audio equalization controls:
/// - Preset selector for quick configuration
/// - Preamp gain control
/// - 10-band frequency equalizer (32Hz to 16kHz)
/// - Sub-bass and bass boost controls
/// - Limiter toggle for anti-clipping protection
/// - Warning indicator for clipping risk
/// - Save preset functionality
///
/// All UI text is in French per requirement 1.5.
/// All controls are wired to EqualizerService for real-time audio processing.
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  EqualizerService? _equalizerService;
  List<EqPreset> _presets = [];
  EqPreset? _selectedPreset;
  
  // Current equalizer state (synced with service)
  double _preamp = 0.0;
  final List<double> _bandLevels = List.filled(10, 0.0);
  double _subBass = 0.0;
  double _bass = 0.0;
  bool _limiterEnabled = true;
  bool _showClippingWarning = false;
  bool _isLoading = true;

  // Frequency band labels
  final List<String> _frequencyLabels = [
    '32',
    '64',
    '125',
    '250',
    '500',
    '1k',
    '2k',
    '4k',
    '8k',
    '16k',
  ];

  @override
  void initState() {
    super.initState();
    _initializeEqualizer();
  }

  /// Initialize equalizer service and load current settings
  Future<void> _initializeEqualizer() async {
    try {
      // Get audio handler and equalizer service
      final audioHandler = AudioServiceInitializer.audioHandler;
      if (audioHandler == null) {
        throw Exception('Audio service not initialized');
      }

      _equalizerService = audioHandler.equalizerService;

      // Load presets from database
      final databaseService = DatabaseService();
      final presetRepo = EqPresetRepositoryImpl(databaseService);
      
      // Ensure built-in presets are initialized (lazy initialization)
      // This is deferred from app startup for better performance
      await presetRepo.initializeBuiltinPresets();
      
      final presets = await presetRepo.getAllEqPresets();

      // Load current equalizer state
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
      setState(() {
        _isLoading = false;
      });
      // Show error after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement de l\'égaliseur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  
                  // Preset selector
                  _buildPresetSelector(),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Preamp control
                  _buildPreampControl(),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Frequency bands
                  _buildFrequencyBands(),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Bass controls
                  _buildBassControls(),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Limiter and warning
                  _buildLimiterControl(),
                  
                  if (_showClippingWarning) ...[
                    const SizedBox(height: 12),
                    _buildClippingWarning(),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Save preset button
                  _buildSavePresetButton(),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Égaliseur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Fermer',
          ),
        ],
      ),
    );
  }

  Widget _buildPresetSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Préréglage',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<EqPreset?>(
            value: _selectedPreset,
            isExpanded: true,
            underline: const SizedBox(),
            hint: const Text('Sélectionner un préréglage'),
            items: [
              const DropdownMenuItem<EqPreset?>(
                value: null,
                child: Text('Personnalisé'),
              ),
              ..._presets.map((preset) {
                return DropdownMenuItem<EqPreset?>(
                  value: preset,
                  child: Text(preset.name),
                );
              }),
            ],
            onChanged: (preset) async {
              if (preset != null && _equalizerService != null) {
                try {
                  // Apply preset to equalizer service
                  await _equalizerService!.applyPreset(preset);
                  
                  // Update UI state
                  setState(() {
                    _selectedPreset = preset;
                    _preamp = _equalizerService!.preamp;
                    _bandLevels.setAll(0, _equalizerService!.bandLevels);
                    _subBass = _equalizerService!.subBass;
                    _bass = _equalizerService!.bass;
                    _limiterEnabled = _equalizerService!.limiterEnabled;
                    _showClippingWarning = _equalizerService!.isClippingRisk();
                  });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'application du préréglage: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } else {
                setState(() {
                  _selectedPreset = null;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreampControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Préampli',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_preamp.toStringAsFixed(1)} dB',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _preamp,
          min: -10.0,
          max: 10.0,
          divisions: 40,
          label: '${_preamp.toStringAsFixed(1)} dB',
          onChanged: (value) async {
            setState(() {
              _preamp = value;
              _selectedPreset = null; // Mark as custom
            });
            
            // Apply to equalizer service in real-time
            if (_equalizerService != null) {
              try {
                await _equalizerService!.setPreamp(value);
                setState(() {
                  _showClippingWarning = _equalizerService!.isClippingRisk();
                });
              } catch (e) {
                // Log error but don't interrupt user interaction
                debugPrint('Error setting preamp: $e');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyBands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bandes de fréquence',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(10, (index) {
              return Expanded(
                child: _buildFrequencyBandSlider(index),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyBandSlider(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // dB value
        Text(
          _bandLevels[index].toStringAsFixed(0),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade400,
          ),
        ),
        
        // Vertical slider
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: _bandLevels[index],
              min: -15.0,
              max: 15.0,
              divisions: 30,
              onChanged: (value) async {
                setState(() {
                  _bandLevels[index] = value;
                  _selectedPreset = null; // Mark as custom
                });
                
                // Apply to equalizer service in real-time
                if (_equalizerService != null) {
                  try {
                    await _equalizerService!.setBandLevel(index, value);
                    setState(() {
                      _showClippingWarning = _equalizerService!.isClippingRisk();
                    });
                  } catch (e) {
                    // Log error but don't interrupt user interaction
                    debugPrint('Error setting band level: $e');
                  }
                }
              },
            ),
          ),
        ),
        
        // Frequency label
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _frequencyLabels[index],
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBassControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Contrôles de basses',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        
        // Sub-bass control
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sub-Bass',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '${_subBass.toStringAsFixed(1)} dB',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Slider(
          value: _subBass,
          min: 0.0,
          max: 12.0,
          divisions: 24,
          label: '${_subBass.toStringAsFixed(1)} dB',
          onChanged: (value) async {
            setState(() {
              _subBass = value;
              _selectedPreset = null; // Mark as custom
            });
            
            // Apply to equalizer service in real-time
            if (_equalizerService != null) {
              try {
                await _equalizerService!.setSubBass(value);
                // Update band levels from service (sub-bass affects bands 0 and 1)
                setState(() {
                  _bandLevels.setAll(0, _equalizerService!.bandLevels);
                  _showClippingWarning = _equalizerService!.isClippingRisk();
                });
              } catch (e) {
                debugPrint('Error setting sub-bass: $e');
              }
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Bass control
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Bass',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              '${_bass.toStringAsFixed(1)} dB',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Slider(
          value: _bass,
          min: 0.0,
          max: 12.0,
          divisions: 24,
          label: '${_bass.toStringAsFixed(1)} dB',
          onChanged: (value) async {
            setState(() {
              _bass = value;
              _selectedPreset = null; // Mark as custom
            });
            
            // Apply to equalizer service in real-time
            if (_equalizerService != null) {
              try {
                await _equalizerService!.setBass(value);
                // Update band levels from service (bass affects bands 2 and 3)
                setState(() {
                  _bandLevels.setAll(0, _equalizerService!.bandLevels);
                  _showClippingWarning = _equalizerService!.isClippingRisk();
                });
              } catch (e) {
                debugPrint('Error setting bass: $e');
              }
            }
          },
        ),
      ],
    );
  }

  Widget _buildLimiterControl() {
    return Row(
      children: [
        Checkbox(
          value: _limiterEnabled,
          onChanged: (value) async {
            final enabled = value ?? true;
            setState(() {
              _limiterEnabled = enabled;
            });
            
            // Apply to equalizer service
            if (_equalizerService != null) {
              try {
                await _equalizerService!.setLimiterEnabled(enabled);
                setState(() {
                  _showClippingWarning = _equalizerService!.isClippingRisk();
                });
              } catch (e) {
                debugPrint('Error setting limiter: $e');
              }
            }
          },
        ),
        const Expanded(
          child: Text(
            'Limiteur activé',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildClippingWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withValues(alpha: 0.3),
        border: Border.all(color: Colors.orange.shade700),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade400,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Risque de distorsion détecté',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavePresetButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showSavePresetDialog();
      },
      icon: const Icon(Icons.save),
      label: const Text('Sauvegarder préréglage'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _showSavePresetDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sauvegarder préréglage'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom du préréglage',
            hintText: 'Mon préréglage personnalisé',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le nom du préréglage ne peut pas être vide'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Create preset from current settings
                final preset = EqPreset(
                  name: name,
                  bandLevels: List.from(_bandLevels),
                  preamp: _preamp,
                  subBass: _subBass,
                  bass: _bass,
                  limiterEnabled: _limiterEnabled,
                  createdAt: DateTime.now(),
                  isBuiltin: false,
                );

                // Save to database
                final databaseService = DatabaseService();
                final presetRepo = EqPresetRepositoryImpl(databaseService);
                await presetRepo.insertEqPreset(preset);

                // Reload presets
                final presets = await presetRepo.getAllEqPresets();
                setState(() {
                  _presets = presets;
                  _selectedPreset = presets.firstWhere(
                    (p) => p.name == name,
                    orElse: () => preset,
                  );
                });

                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Préréglage sauvegardé'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la sauvegarde: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
