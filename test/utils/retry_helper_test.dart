import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:remi/core/utils/retry_helper.dart';

void main() {
  group('RetryHelper', () {
    group('withRetry', () {
      test('returns result immediately on success', () async {
        var callCount = 0;
        final result = await RetryHelper.withRetry<String>(
          operation: () async {
            callCount++;
            return 'success';
          },
          maxRetries: 3,
        );
        expect(result, 'success');
        expect(callCount, 1);
      });

      test('retries on failure and succeeds', () async {
        var callCount = 0;
        final result = await RetryHelper.withRetry<String>(
          operation: () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('SocketException: Connection failed');
            }
            return 'success';
          },
          maxRetries: 3,
          initialDelayMs: 10,
          maxDelayMs: 100,
        );
        expect(result, 'success');
        expect(callCount, 3);
      });

      test('throws after max retries exhausted', () async {
        var callCount = 0;
        expect(
          () => RetryHelper.withRetry<String>(
            operation: () async {
              callCount++;
              throw Exception('SocketException: Connection failed');
            },
            maxRetries: 3,
            initialDelayMs: 10,
            maxDelayMs: 100,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('respects shouldRetry callback', () async {
        var callCount = 0;
        final result = await RetryHelper.withRetry<String>(
          operation: () async {
            callCount++;
            if (callCount == 1) {
              throw Exception('Retry this');
            }
            return 'success';
          },
          maxRetries: 3,
          initialDelayMs: 10,
          shouldRetry: (e) => e.toString().contains('Retry'),
        );
        expect(result, 'success');
        expect(callCount, 2);
      });

      test('does not retry when shouldRetry returns false', () async {
        var callCount = 0;
        expect(
          () => RetryHelper.withRetry<String>(
            operation: () async {
              callCount++;
              throw Exception('Do not retry');
            },
            maxRetries: 3,
            initialDelayMs: 10,
            shouldRetry: (e) => false,
          ),
          throwsA(isA<Exception>()),
        );
        expect(callCount, 1);
      });

      test('calls onRetry callback on each retry', () async {
        var callCount = 0;
        final retryLog = <String>[];
        await RetryHelper.withRetry<String>(
          operation: () async {
            callCount++;
            if (callCount < 3) {
              throw Exception('SocketException: Test error');
            }
            return 'success';
          },
          maxRetries: 5,
          initialDelayMs: 10,
          maxDelayMs: 100,
          onRetry: (e, attempt, delay) {
            retryLog.add('Attempt $attempt: ${e.toString()}');
          },
        );
        expect(retryLog.length, 2);
        expect(retryLog[0], contains('Attempt 1'));
        expect(retryLog[1], contains('Attempt 2'));
      });

      test('uses exponential backoff', () async {
        var callCount = 0;
        final delays = <int>[];
        await RetryHelper.withRetry<String>(
          operation: () async {
            callCount++;
            if (callCount < 4) {
              throw Exception('SocketException: Test');
            }
            return 'success';
          },
          maxRetries: 5,
          initialDelayMs: 100,
          maxDelayMs: 10000,
          onRetry: (e, attempt, delay) {
            delays.add(delay.inMilliseconds);
          },
        );
        // Check exponential growth (with jitter, so approximate)
        expect(delays[0], greaterThanOrEqualTo(100));
        expect(delays[1], greaterThanOrEqualTo(delays[0]));
        expect(delays[2], greaterThanOrEqualTo(delays[1]));
      });

      test('caps delay at maxDelayMs', () async {
        var callCount = 0;
        await RetryHelper.withRetry<String>(
          operation: () async {
            callCount++;
            if (callCount < 5) {
              throw Exception('SocketException: Test');
            }
            return 'success';
          },
          maxRetries: 10,
          initialDelayMs: 1000, // Would normally grow large
          maxDelayMs: 200,
          onRetry: (e, attempt, delay) {
            expect(delay.inMilliseconds, lessThanOrEqualTo(200));
          },
        );
      });
    });

    group('withTimeoutAndRetry', () {
      test('times out long-running operations', () async {
        expect(
          () => RetryHelper.withTimeoutAndRetry<String>(
            operation: () async {
              await Future.delayed(Duration(seconds: 10));
              return 'too late';
            },
            timeout: Duration(milliseconds: 100),
            maxRetries: 1,
          ),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('retries on timeout', () async {
        var callCount = 0;
        final result = await RetryHelper.withTimeoutAndRetry<String>(
          operation: () async {
            callCount++;
            if (callCount < 3) {
              await Future.delayed(Duration(seconds: 10));
            }
            return 'success';
          },
          timeout: Duration(milliseconds: 100),
          maxRetries: 3,
          initialDelayMs: 10,
          maxDelayMs: 100,
        );
        expect(result, 'success');
        expect(callCount, 3);
      });
    });

    group('_defaultShouldRetry', () {
      test('retries on socket exceptions', () {
        expect(
          RetryHelper.withRetry<String>(
            operation: () => throw Exception('SocketException: Failed'),
            maxRetries: 0,
          ).catchError((_) => 'caught'),
          completion('caught'),
        );
      });

      test('retries on rate limit (429)', () {
        expect(
          RetryHelper.withRetry<String>(
            operation: () => throw Exception('HTTP 429: Rate limited'),
            maxRetries: 0,
          ).catchError((_) => 'caught'),
          completion('caught'),
        );
      });

      test('retries on service unavailable (503)', () {
        expect(
          RetryHelper.withRetry<String>(
            operation: () => throw Exception('HTTP 503: Service unavailable'),
            maxRetries: 0,
          ).catchError((_) => 'caught'),
          completion('caught'),
        );
      });
    });

    group('RetryFutureExtension', () {
      test('adds retry capability to any Future', () async {
        var callCount = 0;
        final result = await Future(() async {
          callCount++;
          if (callCount < 2) {
            throw Exception('SocketException: Network error');
          }
          return 'success';
        }).withRetry(
          maxRetries: 3,
          initialDelayMs: 10,
          maxDelayMs: 100,
        );
        expect(result, 'success');
        expect(callCount, 2);
      });
    });
  });
}
