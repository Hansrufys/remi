import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:remi/core/constants/app_constants.dart';

/// Utility class for retrying operations with exponential backoff
class RetryHelper {
  /// Executes an async operation with automatic retry on failure
  ///
  /// Uses exponential backoff with jitter to avoid thundering herd.
  /// Retries up to [maxRetries] times with increasing delays.
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = AppConstants.maxApiRetries,
    int initialDelayMs = AppConstants.retryInitialDelayMs,
    int maxDelayMs = AppConstants.retryMaxDelayMs,
    bool Function(Exception)? shouldRetry,
    void Function(Exception, int, Duration)? onRetry,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        if (e is! Exception) rethrow;
        lastException = e;

        // Check if we should retry
        final shouldRetryThis = shouldRetry?.call(e) ?? _defaultShouldRetry(e);
        if (!shouldRetryThis || attempt >= maxRetries) {
          rethrow;
        }

        attempt++;

        // Calculate delay with exponential backoff + jitter
        final baseDelay = initialDelayMs * (1 << (attempt - 1));
        final jitter = _randomJitter(initialDelayMs ~/ 2);
        final delay = Duration(
          milliseconds: (baseDelay + jitter).clamp(0, maxDelayMs),
        );

        // Log retry attempt
        debugPrint(
          'RetryHelper: Attempt $attempt/$maxRetries after ${delay.inMilliseconds}ms',
        );
        debugPrint('RetryHelper: Exception was: $e');

        // Callback for custom retry handling
        onRetry?.call(e, attempt, delay);

        // Wait before retry
        await Future.delayed(delay);
      }
    }

    // Should never reach here, but just in case
    throw lastException ?? Exception('Retry failed without exception');
  }

  /// Default logic for determining if an error should be retried
  static bool _defaultShouldRetry(Exception e) {
    // Retry on network-related errors
    final errorString = e.toString().toLowerCase();
    return errorString.contains('socket') ||
        errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('429') || // Rate limit
        errorString.contains('503') || // Service unavailable
        errorString.contains('502') || // Bad gateway
        errorString.contains('504'); // Gateway timeout
  }

  /// Generates random jitter to avoid synchronized retries
  static int _randomJitter(int maxJitter) {
    return DateTime.now().microsecondsSinceEpoch % maxJitter;
  }

  /// Executes an operation with timeout and retry
  static Future<T> withTimeoutAndRetry<T>({
    required Future<T> Function() operation,
    Duration timeout = const Duration(seconds: AppConstants.apiTimeoutSeconds),
    int maxRetries = AppConstants.maxApiRetries,
    void Function(Exception, int, Duration)? onRetry,
  }) async {
    return withRetry<T>(
      operation: () => operation().timeout(timeout),
      maxRetries: maxRetries,
      onRetry: onRetry,
    );
  }
}

/// Extension to easily add retry capability to any Future
extension RetryFutureExtension<T> on Future<T> {
  /// Wraps this Future with retry logic
  Future<T> withRetry({
    int maxRetries = AppConstants.maxApiRetries,
    bool Function(Exception)? shouldRetry,
    void Function(Exception, int, Duration)? onRetry,
  }) {
    return RetryHelper.withRetry<T>(
      operation: () => this,
      maxRetries: maxRetries,
      shouldRetry: shouldRetry,
      onRetry: onRetry,
    );
  }
}
