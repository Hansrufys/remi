/// Application-wide constants
///
/// This file centralizes magic numbers and hardcoded values
/// to improve maintainability and reduce errors.
class AppConstants {
  AppConstants._();

  // ============================================================
  // Notification IDs
  // ============================================================

  /// Base ID for memory-related notifications
  static const int notificationIdBase = 1000;

  /// Notification ID for daily summary reminders
  static const int dailySummaryNotificationId = 1001;

  /// Notification ID for task reminders
  static const int taskReminderNotificationId = 1002;

  /// Notification ID for pattern alerts
  static const int patternAlertNotificationId = 1003;

  /// Notification ID for Spino reactions
  static const int spinoReactionNotificationId = 1004;

  /// Legacy notification IDs (to be migrated)
  /// TODO: Migrate these to use notificationIdBase + offset
  static const int legacyNotificationIdPrimary = 9999;
  static const int legacyNotificationIdSecondary = 9998;

  // ============================================================
  // API & Network
  // ============================================================

  /// Maximum retries for API calls
  static const int maxApiRetries = 3;

  /// Initial delay before first retry (milliseconds)
  static const int retryInitialDelayMs = 1000;

  /// Maximum delay between retries (milliseconds)
  static const int retryMaxDelayMs = 10000;

  /// API request timeout (seconds)
  static const int apiTimeoutSeconds = 30;

  // ============================================================
  // Memory Processing
  // ============================================================

  /// Minimum text length to consider valid for processing
  static const int minMemoryTextLength = 3;

  /// Maximum entries to return in recent queries
  static const int maxRecentEntries = 50;

  /// Default limit for search results
  static const int defaultSearchLimit = 20;

  // ============================================================
  // UI & Animation
  // ============================================================

  /// Default animation duration (milliseconds)
  static const int defaultAnimationDurationMs = 300;

  /// SnackBar display duration (seconds)
  static const int snackBarDurationSeconds = 4;

  /// Dialog animation duration (milliseconds)
  static const int dialogAnimationDurationMs = 200;

  // ============================================================
  // Storage Keys
  // ============================================================

  /// SharedPreferences key for API key
  static const String apiKeyPreferenceKey = 'groq_api_key';

  /// SharedPreferences key for user preferences
  static const String userPreferencesKey = 'user_preferences';

  /// SharedPreferences key for onboarding completed
  static const String onboardingCompletedKey = 'onboarding_completed';

  // ============================================================
  // Date/Time Formatting
  // ============================================================

  /// Default date format for display
  static const String defaultDateFormat = 'dd.MM.yyyy';

  /// Default time format for display
  static const String defaultTimeFormat = 'HH:mm';

  /// ISO 8601 date format for storage
  static const String isoDateFormat = 'yyyy-MM-ddTHH:mm:ss';

  // ============================================================
  // Validation
  // ============================================================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum tag name length
  static const int maxTagNameLength = 30;

  /// Maximum tags per entry
  static const int maxTagsPerEntry = 10;
}

/// Notification ID generator for type-safe notification management
class NotificationIdGenerator {
  static const int _baseId = AppConstants.notificationIdBase;

  /// Generates a unique notification ID based on memory entry UUID hash
  static int fromMemoryUuid(String uuid) {
    return _baseId + (uuid.hashCode & 0x7FFFFFFF) % 10000;
  }

  /// Generates a notification ID for a specific type and offset
  static int forType(NotificationType type, [int offset = 0]) {
    return _baseId + type.index * 100 + offset;
  }
}

/// Types of notifications for categorization
enum NotificationType {
  dailySummary,
  taskReminder,
  patternAlert,
  spinoReaction,
  systemAlert,
  custom,
}
