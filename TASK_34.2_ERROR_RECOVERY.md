# Task 34.2: Error Recovery Mechanisms Implementation

## Overview

This document describes the error recovery mechanisms implemented for the BassPro Player app, covering automatic retry with exponential backoff, manual retry options, library rescan for missing files, and automatic skip on playback failure.

## Requirements Addressed

- **Requirement 6.3**: Invalid stream error handling with retry option
- **Requirement 6.4**: Network loss handling during streaming
- **Requirement 23.3**: Error handling with user-friendly error messages

## Components Implemented

### 1. Retry Handler with Exponential Backoff

**Location**: `lib/core/utils/retry_handler.dart`

A comprehensive retry utility that implements exponential backoff with jitter to prevent thundering herd problems.

**Features**:
- Configurable maximum retry attempts (default: 3)
- Exponential backoff with jitter for retry delays
- Initial delay: 1000ms, max delay: 10000ms
- Smart error detection (determines if error is retryable)
- Specialized stream retry with longer delays (initial: 2000ms, max: 30000ms)
- Callback support for retry notifications

**Key Methods**:

```dart
// Generic retry with exponential backoff
Future<T> retry<T>({
  required Future<T> Function() operation,
  int maxAttempts = 3,
  int initialDelay = 1000,
  int maxDelay = 10000,
  bool Function(Object error)? shouldRetry,
})

// Specialized stream retry
Future<T> retryStream<T>({
  required String streamUrl,
  required Future<T> Function() connectFunction,
  int maxAttempts = 5,
  void Function(int attempt, Duration delay)? onRetry,
})
```

**Retry Logic**:
1. Attempt operation
2. On failure, check if error is retryable
3. If not retryable, fail immediately
4. If retryable and attempts remain:
   - Calculate delay: `min(initialDelay * 2^(attempt-1), maxDelay)`
   - Add random jitter (0-25% of delay)
   - Wait for calculated delay
   - Retry operation
5. If all attempts exhausted, throw last error

**Retryable Errors**:
- Network errors (except invalid URLs)
- Temporary audio errors (not unsupported formats or corrupted files)
- Scanner errors
- Socket exceptions
- Timeout exceptions
- Connection errors

**Non-Retryable Errors**:
- Invalid URLs
- Unsupported audio formats
- Corrupted files
- Permission errors
- Database corruption

### 2. Enhanced Error Display with Track Names

**Location**: `lib/presentation/widgets/error_display.dart`

Enhanced the error display utilities to include track names in error notifications.

**Changes**:
- Added optional `trackName` parameter to `showErrorSnackBar()`
- Error messages now include track name when provided
- Format: `"[Error Message]\nPiste: [Track Name]"`

**Usage Example**:
```dart
showErrorSnackBar(
  context,
  NetworkError.streamUnreachable(url),
  trackName: 'My Favorite Song',
  onRetry: () => retryPlayback(),
);
```

### 3. Automatic Retry for Streaming

**Location**: `lib/presentation/screens/streaming/streaming_screen.dart`

Integrated automatic retry with exponential backoff for stream playback.

**Implementation**:
- Uses `RetryHandler.retryStream()` for all stream connections
- Maximum 5 retry attempts for streams
- Shows retry notifications to user: "Reconnexion... (tentative X)"
- Automatic backoff: 2s, 4s, 8s, 16s, 30s between attempts
- Falls back to error dialog if all retries fail
- Includes stream name in error notifications

**Retry Flow**:
1. User taps stream to play
2. Show buffering indicator
3. Attempt connection with retry handler
4. On failure, wait with exponential backoff
5. Show retry notification to user
6. Retry connection (up to 5 times)
7. On success: play stream, update history
8. On final failure: show error dialog with manual retry option

**Error Handling**:
- Socket exceptions → "Flux inaccessible" + auto retry
- Timeout exceptions → "Délai d'attente dépassé" + auto retry
- Format exceptions → "URL invalide" (no retry)
- Network exceptions → "Erreur de connexion réseau" + auto retry

### 4. Enhanced Audio Handler Error Notifications

**Location**: `lib/data/services/audio/basspro_audio_handler.dart`

Enhanced the audio handler to include track names in error messages.

**Changes**:
- Error messages now include current track name
- Format: `"[Error Message]\nPiste: [Track Name]"`
- Automatic skip to next track on playback failure (already implemented)
- Improved logging with track context

**Error Types Handled**:
- Corrupted files → Skip to next track
- Unsupported formats → Skip to next track
- File not found → Skip to next track
- Network errors → Show error, allow retry

**Skip Behavior**:
- Automatically skips to next track if available
- Logs track name that failed
- Updates playback state with error message
- If no next track, stops playback with error

### 5. Missing Files Banner and Rescan Suggestion

**Location**: `lib/presentation/widgets/missing_files_banner.dart`

Created widgets to suggest library rescan when files are missing.

**Components**:

1. **MissingFilesBanner Widget**:
   - Displays warning banner when missing files detected
   - Shows count of missing files
   - Provides "Rescanner" button
   - Styled with error colors for visibility

2. **showRescanSuggestion Function**:
   - Shows snackbar with rescan action
   - Includes file name if provided
   - 5-second duration for user to see
   - Direct action button to trigger rescan

**Usage Example**:
```dart
// Show banner in UI
MissingFilesBanner(
  missingCount: 5,
  onRescan: () => _rescanLibrary(),
)

// Show snackbar notification
showRescanSuggestion(
  context,
  fileName: 'song.mp3',
  onRescan: () => _rescanLibrary(),
)
```

### 6. Library Rescan Integration

**Location**: `lib/presentation/screens/settings/settings_screen.dart` (already implemented)

The library rescan functionality was already implemented in Task 28.2.

**Features**:
- Manual rescan button in Settings screen
- Shows progress during scan
- Updates library with new/removed files
- Can be triggered from error recovery flows

**Integration Points**:
- Settings screen: Manual rescan option
- Missing files banner: Quick rescan action
- Error handlers: Suggest rescan for file not found errors

## Error Recovery Flows

### Flow 1: Stream Connection Failure with Auto-Retry

```
User taps stream
    ↓
Show buffering indicator
    ↓
Attempt connection (Attempt 1)
    ↓
[FAIL] Network error
    ↓
Wait 2 seconds (with jitter)
    ↓
Show "Reconnexion... (tentative 2)"
    ↓
Attempt connection (Attempt 2)
    ↓
[FAIL] Network error
    ↓
Wait 4 seconds (with jitter)
    ↓
Show "Reconnexion... (tentative 3)"
    ↓
Attempt connection (Attempt 3)
    ↓
[SUCCESS] Stream connected
    ↓
Play stream, update history
    ↓
Show "Lecture de [stream name]"
```

### Flow 2: Stream Connection Failure After All Retries

```
User taps stream
    ↓
Auto-retry attempts (1-5)
    ↓
All attempts fail
    ↓
Show error dialog with:
  - Error message
  - Stream name
  - Manual retry button
    ↓
User clicks retry
    ↓
Restart auto-retry flow
```

### Flow 3: Playback Failure with Auto-Skip

```
Playing track
    ↓
Playback error (corrupted file)
    ↓
Log error with track name
    ↓
Update playback state with error
    ↓
Check if next track available
    ↓
[YES] Skip to next track automatically
    ↓
Continue playback
    ↓
Show notification: "Fichier audio corrompu\nPiste: [track name]"
```

### Flow 4: Missing File with Rescan Suggestion

```
User tries to play track
    ↓
File not found error
    ↓
Show error notification with track name
    ↓
Show rescan suggestion snackbar
    ↓
User clicks "Rescanner"
    ↓
Navigate to Settings
    ↓
Trigger library rescan
    ↓
Update library with current files
    ↓
Remove missing files from database
```

## User Experience Improvements

### 1. Transparent Auto-Retry
- Users see "Reconnexion..." notifications
- No manual intervention required for temporary failures
- Exponential backoff prevents rapid retry spam
- Jitter prevents server overload

### 2. Informative Error Messages
- All errors include track/stream name
- Clear indication of what failed
- Actionable suggestions (retry, rescan)
- French language throughout

### 3. Graceful Degradation
- Auto-skip on unrecoverable playback errors
- Playback continues with next track
- User can continue listening without interruption
- Failed tracks logged for debugging

### 4. Easy Recovery Options
- Retry buttons on all recoverable errors
- Quick rescan action for missing files
- Settings integration for manual control
- Context-aware error handling

## Testing Recommendations

### Manual Testing Scenarios

1. **Stream Auto-Retry**:
   - Disable network temporarily
   - Try to play stream
   - Verify retry notifications appear
   - Re-enable network during retry
   - Verify stream connects successfully

2. **Stream Retry Exhaustion**:
   - Use invalid stream URL
   - Verify 5 retry attempts
   - Verify error dialog appears
   - Verify manual retry button works

3. **Playback Auto-Skip**:
   - Add corrupted file to queue
   - Play queue
   - Verify auto-skip to next track
   - Verify error notification with track name

4. **Missing File Rescan**:
   - Delete audio file from device
   - Try to play deleted file
   - Verify error notification
   - Verify rescan suggestion
   - Trigger rescan
   - Verify file removed from library

5. **Network Loss During Streaming**:
   - Start playing stream
   - Disable network
   - Verify error notification
   - Re-enable network
   - Verify retry option works

### Automated Testing

Create unit tests for:
- RetryHandler exponential backoff calculation
- Retry attempt counting
- Jitter randomization
- Error type detection
- Retryable error identification

Create integration tests for:
- Stream retry flow end-to-end
- Auto-skip on playback failure
- Error notification display
- Rescan suggestion flow

## Performance Considerations

### Retry Delays
- Initial delay: 2 seconds (streams), 1 second (general)
- Maximum delay: 30 seconds (streams), 10 seconds (general)
- Prevents rapid retry spam
- Gives network time to recover

### Jitter
- Random variation: 0-25% of delay
- Prevents synchronized retries
- Reduces server load spikes
- Improves success rate

### Resource Usage
- Retry handler is stateless
- No memory leaks from retry loops
- Proper cleanup on cancellation
- Efficient error detection

## Requirements Validation

### Requirement 6.3: Invalid Stream Error Handling ✅
- Error message displayed with retry option
- Manual retry button in error dialog
- Automatic retry with exponential backoff
- Stream name included in error message

### Requirement 6.4: Network Loss Handling ✅
- Audio handler pauses on network loss
- Error notification displayed
- Automatic retry for streams
- Manual retry option available

### Requirement 23.3: Error Handling with User-Friendly Messages ✅
- All error messages in French
- Track/stream names included
- Clear, actionable messages
- Appropriate recovery options

## Summary

The error recovery mechanisms implementation provides:

1. **Automatic Retry**: Exponential backoff with jitter for streams (up to 5 attempts)
2. **Manual Retry**: Retry buttons on all recoverable errors
3. **Auto-Skip**: Automatic skip to next track on playback failure
4. **Rescan Integration**: Quick rescan option for missing files
5. **Informative Notifications**: All errors include track/stream names
6. **Graceful Degradation**: Playback continues despite individual track failures
7. **User Control**: Manual retry and rescan options always available

The implementation follows Flutter best practices and provides a professional user experience even when errors occur. Users experience minimal disruption from temporary failures, while permanent failures are clearly communicated with appropriate recovery options.

