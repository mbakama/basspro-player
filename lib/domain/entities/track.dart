/// Track entity representing a music track in the domain layer.
///
/// This is an immutable domain model that represents a music track with all
/// its metadata. It supports serialization to/from database maps and provides
/// a copyWith method for creating modified copies.
class Track {
  final int? id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String uri;
  final String? artworkUri;
  final DateTime dateAdded;
  final int playCount;
  final DateTime? lastPlayedAt;
  final bool isFavorite;

  const Track({
    this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.uri,
    this.artworkUri,
    required this.dateAdded,
    this.playCount = 0,
    this.lastPlayedAt,
    this.isFavorite = false,
  });

  /// Creates a copy of this Track with the given fields replaced with new values.
  Track copyWith({
    int? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? uri,
    String? artworkUri,
    DateTime? dateAdded,
    int? playCount,
    DateTime? lastPlayedAt,
    bool? isFavorite,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      uri: uri ?? this.uri,
      artworkUri: artworkUri ?? this.artworkUri,
      dateAdded: dateAdded ?? this.dateAdded,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Converts this Track to a Map for database serialization.
  ///
  /// Duration is stored as milliseconds (INTEGER).
  /// DateTime values are stored as milliseconds since epoch (INTEGER).
  /// Boolean values are stored as INTEGER (0 or 1).
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration': duration.inMilliseconds,
      'uri': uri,
      'artwork_uri': artworkUri,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'play_count': playCount,
      'last_played_at': lastPlayedAt?.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  /// Creates a Track from a database Map.
  ///
  /// Converts INTEGER values back to Duration, DateTime, and bool types.
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id'] as int?,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: map['album'] as String,
      duration: Duration(milliseconds: map['duration'] as int),
      uri: map['uri'] as String,
      artworkUri: map['artwork_uri'] as String?,
      dateAdded: DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int),
      playCount: map['play_count'] as int? ?? 0,
      lastPlayedAt: map['last_played_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_played_at'] as int)
          : null,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Track &&
        other.id == id &&
        other.title == title &&
        other.artist == artist &&
        other.album == album &&
        other.duration == duration &&
        other.uri == uri &&
        other.artworkUri == artworkUri &&
        other.dateAdded == dateAdded &&
        other.playCount == playCount &&
        other.lastPlayedAt == lastPlayedAt &&
        other.isFavorite == isFavorite;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      artist,
      album,
      duration,
      uri,
      artworkUri,
      dateAdded,
      playCount,
      lastPlayedAt,
      isFavorite,
    );
  }

  @override
  String toString() {
    return 'Track(id: $id, title: $title, artist: $artist, album: $album, '
        'duration: $duration, uri: $uri, artworkUri: $artworkUri, '
        'dateAdded: $dateAdded, playCount: $playCount, '
        'lastPlayedAt: $lastPlayedAt, isFavorite: $isFavorite)';
  }
}
