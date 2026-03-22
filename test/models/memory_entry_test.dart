import 'package:flutter_test/flutter_test.dart';
import 'package:remi/data/models/memory_entry.dart';

void main() {
  group('MemoryEntry', () {
    late MemoryEntry testEntry;

    setUp(() {
      testEntry = MemoryEntry(
        uuid: 'test-uuid-123',
        rawText: 'Test raw text',
        type: EntryType.insight,
        summary: 'Test summary',
        createdAt: DateTime(2026, 3, 22, 14, 0),
        tags: ['test', 'unit'],
        personMentioned: 'John',
      );
    });

    group('constructor', () {
      test('creates entry with required fields', () {
        expect(testEntry.uuid, 'test-uuid-123');
        expect(testEntry.rawText, 'Test raw text');
        expect(testEntry.type, EntryType.insight);
        expect(testEntry.summary, 'Test summary');
        expect(testEntry.isCompleted, false);
        expect(testEntry.isProcessing, false);
      });

      test('sets default values correctly', () {
        expect(testEntry.isCompleted, false);
        expect(testEntry.isProcessing, false);
        expect(testEntry.tags, ['test', 'unit']);
      });

      test('allows null optional fields', () {
        expect(testEntry.id, isNull);
        expect(testEntry.taskDescription, isNull);
        expect(testEntry.timeHint, isNull);
        expect(testEntry.spinoReaction, isNull);
      });
    });

    group('toMap', () {
      test('converts entry to map correctly', () {
        final map = testEntry.toMap();

        expect(map['uuid'], 'test-uuid-123');
        expect(map['raw_text'], 'Test raw text');
        expect(map['type'], 'insight');
        expect(map['summary'], 'Test summary');
        expect(map['is_completed'], 0);
        expect(map['is_processing'], 0);
        expect(map['tags'], 'test,unit');
        expect(map['person_mentioned'], 'John');
      });

      test('excludes null id from map', () {
        final map = testEntry.toMap();
        expect(map.containsKey('id'), false);
      });

      test('includes id when present', () {
        final entryWithId = testEntry.copyWith(id: 42);
        final map = entryWithId.toMap();
        expect(map['id'], 42);
      });

      test('converts completed status correctly', () {
        final completedEntry = testEntry.copyWith(isCompleted: true);
        final map = completedEntry.toMap();
        expect(map['is_completed'], 1);
      });

      test('converts processing status correctly', () {
        final processingEntry = testEntry.copyWith(isProcessing: true);
        final map = processingEntry.toMap();
        expect(map['is_processing'], 1);
      });
    });

    group('fromMap', () {
      test('creates entry from map correctly', () {
        final map = {
          'uuid': 'test-uuid-456',
          'raw_text': 'Raw text from map',
          'type': 'fact',
          'summary': 'Summary from map',
          'created_at': '2026-03-22T14:00:00.000',
          'is_completed': 1,
          'is_processing': 0,
          'tags': 'tag1,tag2,tag3',
          'person_mentioned': 'Jane',
        };

        final entry = MemoryEntry.fromMap(map);

        expect(entry.uuid, 'test-uuid-456');
        expect(entry.rawText, 'Raw text from map');
        expect(entry.type, EntryType.factPattern);
        expect(entry.summary, 'Summary from map');
        expect(entry.isCompleted, true);
        expect(entry.isProcessing, false);
        expect(entry.tags, ['tag1', 'tag2', 'tag3']);
        expect(entry.personMentioned, 'Jane');
      });

      test('handles empty tags correctly', () {
        final map = {
          'uuid': 'test-uuid',
          'raw_text': 'text',
          'type': 'actionable',
          'summary': 'summary',
          'created_at': '2026-03-22T14:00:00.000',
          'tags': '',
        };

        final entry = MemoryEntry.fromMap(map);
        expect(entry.tags, isEmpty);
      });

      test('handles null tags correctly', () {
        final map = {
          'uuid': 'test-uuid',
          'raw_text': 'text',
          'type': 'actionable',
          'summary': 'summary',
          'created_at': '2026-03-22T14:00:00.000',
          'tags': null,
        };

        final entry = MemoryEntry.fromMap(map);
        expect(entry.tags, isEmpty);
      });

      test('defaults to unknown type for invalid type string', () {
        final map = {
          'uuid': 'test-uuid',
          'raw_text': 'text',
          'type': 'invalid_type',
          'summary': 'summary',
          'created_at': '2026-03-22T14:00:00.000',
        };

        final entry = MemoryEntry.fromMap(map);
        expect(entry.type, EntryType.unknown);
      });

      test('defaults is_completed to false when missing', () {
        final map = {
          'uuid': 'test-uuid',
          'raw_text': 'text',
          'type': 'actionable',
          'summary': 'summary',
          'created_at': '2026-03-22T14:00:00.000',
        };

        final entry = MemoryEntry.fromMap(map);
        expect(entry.isCompleted, false);
      });

      test('parses remindAt correctly', () {
        final map = {
          'uuid': 'test-uuid',
          'raw_text': 'text',
          'type': 'actionable',
          'summary': 'summary',
          'created_at': '2026-03-22T14:00:00.000',
          'remind_at': '2026-03-25T09:30:00.000',
        };

        final entry = MemoryEntry.fromMap(map);
        expect(entry.remindAt, DateTime(2026, 3, 25, 9, 30));
      });

      test('handles invalid remindAt gracefully', () {
        final map = {
          'uuid': 'test-uuid',
          'raw_text': 'text',
          'type': 'actionable',
          'summary': 'summary',
          'created_at': '2026-03-22T14:00:00.000',
          'remind_at': 'invalid-date',
        };

        final entry = MemoryEntry.fromMap(map);
        expect(entry.remindAt, isNull);
      });
    });

    group('copyWith', () {
      test('copies entry with new values', () {
        final copied = testEntry.copyWith(
          summary: 'New summary',
          isCompleted: true,
        );

        expect(copied.uuid, testEntry.uuid);
        expect(copied.summary, 'New summary');
        expect(copied.isCompleted, true);
        expect(copied.rawText, testEntry.rawText);
      });

      test('preserves original when no changes', () {
        final copied = testEntry.copyWith();

        expect(copied.uuid, testEntry.uuid);
        expect(copied.summary, testEntry.summary);
        expect(copied.isCompleted, testEntry.isCompleted);
      });

      test('can update id', () {
        final copied = testEntry.copyWith(id: 100);
        expect(copied.id, 100);
      });

      test('can update tags', () {
        final copied = testEntry.copyWith(tags: ['new', 'tags']);
        expect(copied.tags, ['new', 'tags']);
      });

      test('can set spinoReaction', () {
        final copied = testEntry.copyWith(spinoReaction: 'pin');
        expect(copied.spinoReaction, 'pin');
      });
    });

    group('EntryType', () {
      test('has all expected types', () {
        expect(EntryType.values, contains(EntryType.actionable));
        expect(EntryType.values, contains(EntryType.insight));
        expect(EntryType.values, contains(EntryType.factPattern));
        expect(EntryType.values, contains(EntryType.pattern));
        expect(EntryType.values, contains(EntryType.unknown));
      });

      test('serializes to string correctly', () {
        expect(EntryType.actionable.name, 'actionable');
        expect(EntryType.insight.name, 'insight');
        expect(EntryType.factPattern.name, 'fact');
        expect(EntryType.pattern.name, 'pattern');
        expect(EntryType.unknown.name, 'unknown');
      });
    });

    group('round-trip serialization', () {
      test('toMap and fromMap are inverse operations', () {
        final original = MemoryEntry(
          id: 42,
          uuid: 'test-uuid-789',
          rawText: 'Original text with more content',
          type: EntryType.pattern,
          summary: 'Pattern detected in behavior',
          createdAt: DateTime(2026, 3, 22, 14, 30),
          isCompleted: true,
          personMentioned: 'Alice',
          tags: ['pattern', 'behavior', 'analysis'],
          taskDescription: 'Analyze this pattern',
          timeHint: 'tomorrow',
          insightDetail: 'Key insight about recurring behavior',
          isProcessing: false,
          spinoReaction: 'glow',
          spinoNotification: 'Pattern worth tracking',
          remindAt: DateTime(2026, 3, 25, 10, 0),
        );

        final map = original.toMap();
        final restored = MemoryEntry.fromMap(map);

        expect(restored.id, original.id);
        expect(restored.uuid, original.uuid);
        expect(restored.rawText, original.rawText);
        expect(restored.type, original.type);
        expect(restored.summary, original.summary);
        expect(restored.createdAt, original.createdAt);
        expect(restored.isCompleted, original.isCompleted);
        expect(restored.personMentioned, original.personMentioned);
        expect(restored.tags, original.tags);
        expect(restored.taskDescription, original.taskDescription);
        expect(restored.timeHint, original.timeHint);
        expect(restored.insightDetail, original.insightDetail);
        expect(restored.isProcessing, original.isProcessing);
        expect(restored.spinoReaction, original.spinoReaction);
        expect(restored.spinoNotification, original.spinoNotification);
        expect(restored.remindAt, original.remindAt);
      });

      test('handles all entry types correctly', () {
        for (final type in EntryType.values) {
          final entry = MemoryEntry(
            uuid: 'test-${type.name}',
            rawText: 'Test for ${type.name}',
            type: type,
            summary: 'Summary for ${type.name}',
            createdAt: DateTime.now(),
          );

          final map = entry.toMap();
          final restored = MemoryEntry.fromMap(map);

          expect(restored.type, type);
        }
      });
    });
  });
}
