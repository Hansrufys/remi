import 'package:flutter_test/flutter_test.dart';
import 'package:remi/data/services/gemini_service.dart';

void main() {
  group('ExtractionResult', () {
    group('fromJson', () {
      test('parses basic extraction result', () {
        final json = {
          'type': 'actionable',
          'summary': 'Test summary',
        };

        final result = ExtractionResult.fromJson(json);

        expect(result.type, 'actionable');
        expect(result.summary, 'Test summary');
        expect(result.personName, isNull);
        expect(result.taskDescription, isNull);
      });

      test('parses all fields correctly', () {
        final json = {
          'type': 'insight',
          'summary': 'Likes coffee',
          'personName': 'Alice',
          'taskDescription': null,
          'remindAt': '2026-03-25T09:00:00',
          'insightDetail': 'Prefers black coffee',
          'spinoReaction': 'catch',
          'spinoNotification': 'Digga, Kaffee nicht vergessen!',
          'globalAction': null,
        };

        final result = ExtractionResult.fromJson(json);

        expect(result.type, 'insight');
        expect(result.summary, 'Likes coffee');
        expect(result.personName, 'Alice');
        expect(result.remindAt, '2026-03-25T09:00:00');
        expect(result.insightDetail, 'Prefers black coffee');
        expect(result.spinoReaction, 'catch');
        expect(result.spinoNotification, 'Digga, Kaffee nicht vergessen!');
      });

      test('handles camelCase to snake_case conversion', () {
        final json = {
          'type': 'pattern',
          'summary': 'Test',
          'person_name': 'Bob', // snake_case variant
        };

        final result = ExtractionResult.fromJson(json);

        expect(result.personName, 'Bob');
      });

      test('defaults to unknown type when missing', () {
        final json = <String, dynamic>{};

        final result = ExtractionResult.fromJson(json);

        expect(result.type, 'unknown');
        expect(result.summary, '');
      });

      test('defaults to empty summary when missing', () {
        final json = {'type': 'actionable'};

        final result = ExtractionResult.fromJson(json);

        expect(result.summary, '');
      });

      test('handles null values gracefully', () {
        final json = {
          'type': 'actionable',
          'summary': 'Test',
          'personName': null,
          'taskDescription': null,
        };

        final result = ExtractionResult.fromJson(json);

        expect(result.personName, isNull);
        expect(result.taskDescription, isNull);
      });

      test('handles mixed case keys', () {
        final json = {
          'TYPE': 'actionable',
          'Summary': 'Test summary',
        };

        final result = ExtractionResult.fromJson(json);

        expect(result.type, 'unknown'); // Should default since 'TYPE' != 'type'
      });
    });

    group('unknown factory', () {
      test('creates unknown result with raw text as summary', () {
        final result = ExtractionResult.unknown('Some raw input text');

        expect(result.type, 'unknown');
        expect(result.summary, 'Some raw input text');
        expect(result.personName, isNull);
        expect(result.taskDescription, isNull);
      });

      test('handles empty string', () {
        final result = ExtractionResult.unknown('');

        expect(result.type, 'unknown');
        expect(result.summary, '');
      });
    });

    group('isValid', () {
      test('returns true for valid actionable result', () {
        final result = ExtractionResult.fromJson({
          'type': 'actionable',
          'summary': 'Valid summary text',
        });

        expect(result.isValid, true);
      });

      test('returns false for unknown type', () {
        final result = ExtractionResult.unknown('Some text');

        expect(result.isValid, false);
      });

      test('returns false for summary shorter than 4 chars', () {
        final result = ExtractionResult.fromJson({
          'type': 'actionable',
          'summary': 'abc',
        });

        expect(result.isValid, false);
      });

      test('returns false for whitespace-only summary', () {
        final result = ExtractionResult.fromJson({
          'type': 'actionable',
          'summary': '   ',
        });

        expect(result.isValid, false);
      });

      test('returns true for summary with exactly 4 chars', () {
        final result = ExtractionResult.fromJson({
          'type': 'insight',
          'summary': 'test',
        });

        expect(result.isValid, true);
      });

      test('returns true for long valid summary', () {
        final result = ExtractionResult.fromJson({
          'type': 'pattern',
          'summary': 'This is a longer summary that provides meaningful context',
        });

        expect(result.isValid, true);
      });
    });
  });

  group('GeminiService', () {
    late GeminiService service;

    setUp(() {
      service = GeminiService();
    });

    group('initialize', () {
      test('sets API key correctly', () {
        service.initialize('test-api-key');
        expect(service.isInitialized, true);
      });

      test('handles empty API key', () {
        service.initialize('');
        expect(service.isInitialized, false);
      });

      test('handles null API key after initialization', () {
        service.initialize('valid-key');
        expect(service.isInitialized, true);

        service.initialize('');
        expect(service.isInitialized, false);
      });

      test('isInitialized returns false by default', () {
        expect(service.isInitialized, false);
      });

      test('can reinitialize with new key', () {
        service.initialize('first-key');
        expect(service.isInitialized, true);

        service.initialize('second-key');
        expect(service.isInitialized, true);
      });
    });

    group('extractMemory (without API)', () {
      test('returns unknown result when not initialized', () async {
        final results = await service.extractMemory('Test input');

        expect(results.length, 1);
        expect(results.first.type, 'unknown');
        expect(results.first.summary, 'Test input');
      });

      test('returns unknown result with empty API key', () async {
        service.initialize('');
        final results = await service.extractMemory('Test input');

        expect(results.length, 1);
        expect(results.first.type, 'unknown');
      });

      test('handles null context parameters gracefully', () async {
        // Not initialized, should return unknown
        final results = await service.extractMemory(
          'Test',
          contextTasks: null,
          personContext: null,
        );

        expect(results.length, 1);
        expect(results.first.type, 'unknown');
      });

      test('handles empty context parameters', () async {
        final results = await service.extractMemory(
          'Test',
          contextTasks: [],
          personContext: [],
        );

        expect(results.length, 1);
        expect(results.first.type, 'unknown');
      });
    });

    group('batchExtractPersonInsights (without API)', () {
      test('returns raw text when not initialized', () async {
        final results = await service.batchExtractPersonInsights(
          personName: 'Alice',
          rawText: 'Some information about Alice',
        );

        expect(results.length, 1);
        expect(results.first, 'Some information about Alice');
      });

      test('handles empty person name', () async {
        service.initialize('test-key');
        final results = await service.batchExtractPersonInsights(
          personName: '',
          rawText: 'Info',
        );

        // Without actual API, will return rawText
        expect(results.length, 1);
      });

      test('handles empty raw text', () async {
        final results = await service.batchExtractPersonInsights(
          personName: 'Bob',
          rawText: '',
        );

        expect(results.length, 1);
      });
    });

    group('querySecondBrain (without API)', () {
      test('returns config message when not initialized', () async {
        final response = await service.querySecondBrain(
          question: 'What do I like?',
          recentMemories: ['I like coffee'],
        );

        expect(response, 'Please configure your Groq API key in Settings.');
      });

      test('handles empty memories list', () async {
        final response = await service.querySecondBrain(
          question: 'Test question',
          recentMemories: [],
        );

        expect(response, 'Please configure your Groq API key in Settings.');
      });

      test('handles empty chat history', () async {
        final response = await service.querySecondBrain(
          question: 'Test',
          recentMemories: ['Memory 1'],
          chatHistory: [],
        );

        expect(response, 'Please configure your Groq API key in Settings.');
      });

      test('handles chat history with entries', () async {
        final chatHistory = [
          {'role': 'user', 'content': 'Previous question'},
          {'role': 'assistant', 'content': 'Previous answer'},
        ];

        final response = await service.querySecondBrain(
          question: 'New question',
          recentMemories: ['Memory'],
          chatHistory: chatHistory,
        );

        expect(response, 'Please configure your Groq API key in Settings.');
      });
    });

    group('API error handling', () {
      test('extractMemory returns unknown on API failure', () async {
        // Without valid API key and actual HTTP, this tests the fallback
        service.initialize('invalid-key');

        // This will fail the HTTP call and return unknown
        final results = await service.extractMemory('Test input');

        expect(results.length, greaterThanOrEqualTo(1));
        expect(results.first.type, 'unknown');
      });
    });
  });
}
