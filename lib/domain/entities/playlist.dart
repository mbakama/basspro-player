/// Playlist entity representing a user-created playlist in the domain layer.
///
/// This is an immutable domain model that represents a playlist with its
/// metadata. It supports serialization to/from database maps and provides
/// a copyWith method for creating modified copies.
class Playlist {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Playlist({
    this.id,
    required this.name,
    required this.createdAt,
  });

  /// Creates a copy of this Playlist with the given fields replaced with new values.
  Playlist copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this Playlist to a Map for database serialization.
  ///
  /// DateTime values are stored as milliseconds since epoch (INTEGER).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Creates a Playlist from a database Map.
  ///
  /// Converts INTEGER values back to DateTime type.
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Playlist &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, createdAt);
  }

  @override
  String toString() {
    return 'Playlist(id: $id, name: $name, createdAt: $createdAt)';
  }
}
