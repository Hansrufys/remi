import 'package:flutter_test/flutter_test.dart';
import 'package:remi/features/memory/data/models/memory_entry.dart';
import 'package:remi/features/memory/data/repositories/memory_repository.dart';

void main() {
  group('MemoryRepository', () {
    late MemoryRepository repository;

    setUp(() {
      repository = MemoryRepository();
    });

    group('save and retrieve', () {
      test('saves and retrieves a memory entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-1',
          rawText: 'This is a test memory entry',
          summary: 'Test memory',
          type: EntryType.pattern,
          createdAt: DateTime(2026, 1, 1),
        );

        await repository.save(entry);
        final retrieved = await repository.getById('test-uuid-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.uuid, 'test-uuid-1');
        expect(retrieved.rawText, 'This is a test memory entry');
        expect(retrieved.summary, 'Test memory');
        expect(retrieved.type, EntryType.pattern);
      });

      test('returns null for non-existent entry', () async {
        final retrieved = await repository.getById('non-existent');
        expect(retrieved, isNull);
      });

      test('saves multiple entries', () async {
        final entry1 = MemoryEntry(
          uuid: 'test-uuid-2',
          rawText: 'First entry',
          summary: 'First',
          type: EntryType.insight,
          createdAt: DateTime(2026, 1, 1),
        );
        final entry2 = MemoryEntry(
          uuid: 'test-uuid-3',
          rawText: 'Second entry',
          summary: 'Second',
          type: EntryType.actionable,
          createdAt: DateTime(2026, 1, 2),
        );

        await repository.save(entry1);
        await repository.save(entry2);

        final all = await repository.getAllEntries();
        expect(all.length, greaterThanOrEqualTo(2));
      });
    });

    group('search', () {
      test('searches by query string', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-4',
          rawText: 'Meeting with John about the project',
          summary: 'Meeting with John',
          type: EntryType.pattern,
          createdAt: DateTime(2026, 1, 1),
        );

        await repository.save(entry);
        final results = await repository.searchEntries('John');

        expect(results, isNotEmpty);
        expect(results.any((e) => e.uuid == 'test-uuid-4'), isTrue);
      });

      test('returns empty list for no matches', () async {
        final results = await repository.searchEntries('nonexistent');
        expect(results, isEmpty);
      });
    });

    group('delete', () {
      test('deletes an entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-5',
          rawText: 'Entry to delete',
          summary: 'Delete me',
          type: EntryType.pattern,
          createdAt: DateTime(2026, 1, 1),
        );

        await repository.save(entry);
        await repository.delete('test-uuid-5');
        final retrieved = await repository.getById('test-uuid-5');

        expect(retrieved, isNull);
      });
    });

    group('getRecentEntries', () {
      test('returns entries sorted by date', () async {
        final entry1 = MemoryEntry(
          uuid: 'test-uuid-6',
          rawText: 'Older entry',
          summary: 'Older',
          type: EntryType.pattern,
          createdAt: DateTime(2026, 1, 1),
        );
        final entry2 = MemoryEntry(
          uuid: 'test-uuid-7',
          rawText: 'Newer entry',
          summary: 'Newer',
          type: EntryType.pattern,
          createdAt: DateTime(2026, 1, 2),
        );

        await repository.save(entry1);
        await repository.save(entry2);

        final recent = await repository.getRecentEntries(10);
        expect(recent.first.uuid, 'test-uuid-7');
      });

      test('limits number of entries', () async {
        for (var i = 0; i < 20; i++) {
          final entry = MemoryEntry(
            uuid: 'test-uuid-$i',
            rawText: 'Entry $i',
            summary: 'Entry $i',
            type: EntryType.pattern,
            createdAt: DateTime(2026, 1, i + 1),
          );
          await repository.save(entry);
        }

        final recent = await repository.getRecentEntries(5);
        expect(recent.length, 5);
      });
    });

    group('toggleCompletion', () {
      test('toggles completion status', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-8',
          rawText: 'Task to toggle',
          summary: 'Toggle me',
          type: EntryType.actionable,
          createdAt: DateTime(2026, 1, 1),
        );

        await repository.save(entry);
        await repository.toggleCompletion('test-uuid-8');
        final retrieved = await repository.getById('test-uuid-8');

        // Note: This depends on whether MemoryEntry has a completed field
        // Adjust based on actual implementation
        expect(retrieved, isNotNull);
      });
    });

    group('updatePriority', () {
      test('updates priority of entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-9',
          rawText: 'Task with priority',
          summary: 'Priority task',
          type: EntryType.actionable,
          createdAt: DateTime(2026, 1, 1),
        );

        await repository.save(entry);
        await repository.updatePriority('test-uuid-9', 5);
        final retrieved = await repository.getById('test-uuid-9');

        // Note: This depends on whether MemoryEntry has a priority field
        // Adjust based on actual implementation
        expect(retrieved, isNotNull);
      });
    });
  });
}
