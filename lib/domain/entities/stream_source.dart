/// StreamSource entity representing an online audio stream in the domain layer.
///
/// This is an immutable domain model that represents a streaming source
/// (radio, podcast, or streaming URL) with its metadata. It supports
/// serialization to/from database maps and provides a copyWith method
/// for creating modified copies.
class StreamSource {
  final int? id;
  final String name;
  final String url;
  final String? category;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? lastPlayedAt;

  const StreamSource({
    this.id,
    required this.name,
    required this.url,
    this.category,
    this.isFavorite = false,
    required this.createdAt,
    this.lastPlayedAt,
  });

  /// Creates a copy of this StreamSource with the given fields replaced with new values.
  StreamSource copyWith({
    int? id,
    String? name,
    String? url,
    String? category,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastPlayedAt,
  }) {
    return StreamSource(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
    );
  }

  /// Converts this StreamSource to a Map for database serialization.
  ///
  /// DateTime values are stored as milliseconds since epoch (INTEGER).
  /// Boolean values are stored as INTEGER (0 or 1).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_played_at': lastPlayedAt?.millisecondsSinceEpoch,
    };
  }

  /// Creates a StreamSource from a database Map.
  ///
  /// Converts INTEGER values back to DateTime and bool types.
  factory StreamSource.fromMap(Map<String, dynamic> map) {
    return StreamSource(
      id: map['id'] as int?,
      name: map['name'] as String,
      url: map['url'] as String,
      category: map['category'] as String?,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastPlayedAt: map['last_played_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played_at'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is StreamSource &&
        other.id == id &&
        other.name == name &&
        other.url == url &&
        other.category == category &&
        other.isFavorite == isFavorite &&
        other.createdAt == createdAt &&
        other.lastPlayedAt == lastPlayedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      url,
      category,
      isFavorite,
      createdAt,
      lastPlayedAt,
    );
  }

  @override
  String toString() {
    return 'StreamSource(id: $id, name: $name, url: $url, '
        'category: $category, isFavorite: $isFavorite, '
        'createdAt: $createdAt, lastPlayedAt: $lastPlayedAt)';
  }
}
