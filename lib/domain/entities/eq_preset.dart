import 'dart:convert';

/// EqPreset entity representing an equalizer preset in the domain layer.
///
/// This is an immutable domain model that represents an equalizer preset
/// with all its settings including band levels, bass boost, and limiter.
/// It supports serialization to/from database maps and provides a copyWith
/// method for creating modified copies.
///
/// The bandLevels list is serialized to JSON string for database storage.
class EqPreset {
  final int? id;
  final String name;
  final List<double> bandLevels;
  final double preamp;
  final double subBass;
  final double bass;
  final double virtualizer;
  final bool limiterEnabled;
  final DateTime createdAt;
  final bool isBuiltin;

  const EqPreset({
    this.id,
    required this.name,
    required this.bandLevels,
    required this.preamp,
    required this.subBass,
    required this.bass,
    this.virtualizer = 0.0,
    this.limiterEnabled = true,
    required this.createdAt,
    this.isBuiltin = false,
  });

  /// Creates a copy of this EqPreset with the given fields replaced with new values.
  EqPreset copyWith({
    int? id,
    String? name,
    List<double>? bandLevels,
    double? preamp,
    double? subBass,
    double? bass,
    double? virtualizer,
    bool? limiterEnabled,
    DateTime? createdAt,
    bool? isBuiltin,
  }) {
    return EqPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bandLevels: bandLevels ?? this.bandLevels,
      preamp: preamp ?? this.preamp,
      subBass: subBass ?? this.subBass,
      bass: bass ?? this.bass,
      virtualizer: virtualizer ?? this.virtualizer,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      createdAt: createdAt ?? this.createdAt,
      isBuiltin: isBuiltin ?? this.isBuiltin,
    );
  }

  /// Converts this EqPreset to a Map for database serialization.
  ///
  /// bandLevels is serialized to JSON string for storage.
  /// DateTime values are stored as milliseconds since epoch (INTEGER).
  /// Boolean values are stored as INTEGER (0 or 1).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'bands_json': jsonEncode(bandLevels),
      'preamp': preamp,
      'sub_bass': subBass,
      'bass': bass,
      'virtualizer': virtualizer,
      'limiter_enabled': limiterEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_builtin': isBuiltin ? 1 : 0,
    };
  }

  /// Creates an EqPreset from a database Map.
  ///
  /// Deserializes bandLevels from JSON string.
  /// Converts INTEGER values back to DateTime and bool types.
  factory EqPreset.fromMap(Map<String, dynamic> map) {
    final bandsJson = map['bands_json'] as String;
    final bandsList = jsonDecode(bandsJson) as List;
    final bandLevels = bandsList.map((e) => (e as num).toDouble()).toList();

    return EqPreset(
      id: map['id'] as int?,
      name: map['name'] as String,
      bandLevels: bandLevels,
      preamp: (map['preamp'] as num).toDouble(),
      subBass: (map['sub_bass'] as num).toDouble(),
      bass: (map['bass'] as num).toDouble(),
      virtualizer: (map['virtualizer'] as num?)?.toDouble() ?? 0.0,
      limiterEnabled: (map['limiter_enabled'] as int? ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isBuiltin: (map['is_builtin'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EqPreset &&
        other.id == id &&
        other.name == name &&
        _listEquals(other.bandLevels, bandLevels) &&
        other.preamp == preamp &&
        other.subBass == subBass &&
        other.bass == bass &&
        other.virtualizer == virtualizer &&
        other.limiterEnabled == limiterEnabled &&
        other.createdAt == createdAt &&
        other.isBuiltin == isBuiltin;
  }

  /// Helper method to compare two lists for equality.
  bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      Object.hashAll(bandLevels),
      preamp,
      subBass,
      bass,
      virtualizer,
      limiterEnabled,
      createdAt,
      isBuiltin,
    );
  }

  @override
  String toString() {
    return 'EqPreset(id: $id, name: $name, bandLevels: $bandLevels, '
        'preamp: $preamp, subBass: $subBass, bass: $bass, '
        'virtualizer: $virtualizer, limiterEnabled: $limiterEnabled, '
        'createdAt: $createdAt, isBuiltin: $isBuiltin)';
  }
}
