/// Utility functions for formatting data
class FormatUtils {
  /// Format duration to MM:SS or HH:MM:SS format
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(1, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Format file size to human-readable format (KB, MB, GB)
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// Format number with thousands separator
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  /// Format decibel value with sign and unit
  static String formatDecibels(double db) {
    final sign = db >= 0 ? '+' : '';
    return '$sign${db.toStringAsFixed(1)} dB';
  }

  /// Format frequency value (Hz or kHz)
  static String formatFrequency(int hz) {
    if (hz < 1000) {
      return '${hz}Hz';
    } else {
      final khz = hz / 1000;
      if (khz == khz.toInt()) {
        return '${khz.toInt()}kHz';
      } else {
        return '${khz.toStringAsFixed(1)}kHz';
      }
    }
  }

  /// Truncate text with ellipsis if it exceeds max length
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 1)}…';
  }

  /// Format play count with appropriate suffix
  static String formatPlayCount(int count) {
    if (count == 0) {
      return 'Jamais écouté';
    } else if (count == 1) {
      return '1 écoute';
    } else {
      return '$count écoutes';
    }
  }

  /// Format track count for playlists
  static String formatTrackCount(int count) {
    if (count == 0) {
      return 'Aucune piste';
    } else if (count == 1) {
      return '1 piste';
    } else {
      return '$count pistes';
    }
  }

  /// Format relative time (e.g., "Il y a 2 heures")
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'À l\'instant';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Il y a $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Il y a $hours heure${hours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'Il y a $days jour${days > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Il y a $weeks semaine${weeks > 1 ? 's' : ''}';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return 'Il y a $months mois';
    } else {
      final years = (difference.inDays / 365).floor();
      return 'Il y a $years an${years > 1 ? 's' : ''}';
    }
  }

  /// Format date to French format (DD/MM/YYYY)
  static String formatDate(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year}';
  }

  /// Format time to French format (HH:MM)
  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format date and time to French format
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  // Private constructor to prevent instantiation
  FormatUtils._();
}
