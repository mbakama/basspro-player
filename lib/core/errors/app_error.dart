/// Base class for all application errors
abstract class AppError implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    if (details != null) {
      return '$message: $details';
    }
    return message;
  }
}

/// Database-related errors
class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory DatabaseError.insertFailed(String entity, [String? details]) {
    return DatabaseError(
      message: 'Échec de l\'insertion de $entity',
      details: details,
    );
  }

  factory DatabaseError.updateFailed(String entity, [String? details]) {
    return DatabaseError(
      message: 'Échec de la mise à jour de $entity',
      details: details,
    );
  }

  factory DatabaseError.deleteFailed(String entity, [String? details]) {
    return DatabaseError(
      message: 'Échec de la suppression de $entity',
      details: details,
    );
  }

  factory DatabaseError.queryFailed([String? details]) {
    return DatabaseError(
      message: 'Échec de la requête de base de données',
      details: details,
    );
  }

  factory DatabaseError.notFound(String entity) {
    return DatabaseError(
      message: '$entity introuvable',
    );
  }

  factory DatabaseError.corruption([String? details]) {
    return DatabaseError(
      message: 'Base de données corrompue',
      details: details,
    );
  }
}

/// Network-related errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory NetworkError.noConnection() {
    return const NetworkError(
      message: 'Aucune connexion réseau',
      details: 'Veuillez vérifier votre connexion Internet',
    );
  }

  factory NetworkError.timeout() {
    return const NetworkError(
      message: 'Délai d\'attente dépassé',
      details: 'La connexion a pris trop de temps',
    );
  }

  factory NetworkError.streamUnreachable(String url) {
    return NetworkError(
      message: 'Flux inaccessible',
      details: 'Impossible de se connecter à $url',
    );
  }

  factory NetworkError.invalidUrl(String url) {
    return NetworkError(
      message: 'URL invalide',
      details: url,
    );
  }

  factory NetworkError.connectionLost() {
    return const NetworkError(
      message: 'Connexion perdue',
      details: 'La connexion réseau a été interrompue',
    );
  }
}

/// Audio playback errors
class AudioError extends AppError {
  const AudioError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory AudioError.unsupportedFormat(String format) {
    return AudioError(
      message: 'Format audio non pris en charge',
      details: format,
    );
  }

  factory AudioError.fileNotFound(String path) {
    return AudioError(
      message: 'Fichier audio introuvable',
      details: path,
    );
  }

  factory AudioError.corruptedFile(String path) {
    return AudioError(
      message: 'Fichier audio corrompu',
      details: path,
    );
  }

  factory AudioError.playbackFailed([String? details]) {
    return AudioError(
      message: 'Échec de la lecture',
      details: details,
    );
  }

  factory AudioError.initializationFailed([String? details]) {
    return AudioError(
      message: 'Échec de l\'initialisation audio',
      details: details,
    );
  }

  factory AudioError.equalizerNotSupported() {
    return const AudioError(
      message: 'Égaliseur non pris en charge',
      details: 'Votre appareil ne prend pas en charge l\'égaliseur',
    );
  }

  factory AudioError.audioFocusLoss() {
    return const AudioError(
      message: 'Perte du focus audio',
      details: 'Une autre application utilise l\'audio',
    );
  }
}

/// Permission-related errors
class PermissionError extends AppError {
  const PermissionError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory PermissionError.storageDenied() {
    return const PermissionError(
      message: 'Permission de stockage refusée',
      details: 'L\'accès au stockage est requis pour scanner votre bibliothèque musicale',
    );
  }

  factory PermissionError.foregroundServiceDenied() {
    return const PermissionError(
      message: 'Permission de service en arrière-plan refusée',
      details: 'Cette permission est requise pour la lecture en arrière-plan',
    );
  }

  factory PermissionError.wakeLockDenied() {
    return const PermissionError(
      message: 'Permission de verrouillage d\'écran refusée',
      details: 'Cette permission est requise pour garder l\'écran allumé',
    );
  }

  factory PermissionError.generic(String permission) {
    return PermissionError(
      message: 'Permission refusée',
      details: permission,
    );
  }
}

/// File system errors
class FileSystemError extends AppError {
  const FileSystemError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory FileSystemError.notFound(String path) {
    return FileSystemError(
      message: 'Fichier introuvable',
      details: path,
    );
  }

  factory FileSystemError.accessDenied(String path) {
    return FileSystemError(
      message: 'Accès refusé',
      details: path,
    );
  }

  factory FileSystemError.storageUnavailable() {
    return const FileSystemError(
      message: 'Stockage non disponible',
      details: 'Le stockage externe n\'est pas accessible',
    );
  }

  factory FileSystemError.insufficientSpace() {
    return const FileSystemError(
      message: 'Espace insuffisant',
      details: 'Pas assez d\'espace de stockage disponible',
    );
  }
}

/// Validation errors
class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory ValidationError.emptyField(String fieldName) {
    return ValidationError(
      message: 'Champ requis',
      details: '$fieldName ne peut pas être vide',
    );
  }

  factory ValidationError.invalidFormat(String fieldName) {
    return ValidationError(
      message: 'Format invalide',
      details: fieldName,
    );
  }

  factory ValidationError.duplicateName(String name) {
    return ValidationError(
      message: 'Nom déjà utilisé',
      details: name,
    );
  }

  factory ValidationError.invalidRange(String fieldName, num min, num max) {
    return ValidationError(
      message: 'Valeur hors limites',
      details: '$fieldName doit être entre $min et $max',
    );
  }
}

/// Library scanner errors
class ScannerError extends AppError {
  const ScannerError({
    required super.message,
    super.details,
    super.stackTrace,
  });

  factory ScannerError.scanFailed([String? details]) {
    return ScannerError(
      message: 'Échec de l\'analyse de la bibliothèque',
      details: details,
    );
  }

  factory ScannerError.noTracksFound() {
    return const ScannerError(
      message: 'Aucune piste trouvée',
      details: 'Aucun fichier audio n\'a été trouvé sur votre appareil',
    );
  }

  factory ScannerError.mediaStoreUnavailable() {
    return const ScannerError(
      message: 'MediaStore non disponible',
      details: 'Impossible d\'accéder au MediaStore Android',
    );
  }
}
