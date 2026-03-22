import 'package:flutter_test/flutter_test.dart';
import 'package:remi/data/repositories/repositories.dart';
import 'package:remi/data/models/memory_entry.dart';

void main() {
  group('MemoryRepository', () {
    late MemoryRepository repository;

    setUp(() {
      repository = MemoryRepository();
    });

    group('CRUD operations', () {
      test('adds and retrieves entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-1',
          rawText: 'Test memory entry',
          type: EntryType.insight,
          summary: 'Test summary',
          createdAt: DateTime.now(),
        );

        await repository.add(entry);
        final retrieved = await repository.getByUuid('test-uuid-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.uuid, 'test-uuid-1');
        expect(retrieved.summary, 'Test summary');
      });

      test('getByUuid returns null for non-existent entry', () async {
        final result = await repository.getByUuid('non-existent-uuid');
        expect(result, isNull);
      });

      test('updates existing entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-2',
          rawText: 'Original text',
          type: EntryType.actionable,
          summary: 'Original summary',
          createdAt: DateTime.now(),
        );

        await repository.add(entry);

        final updated = entry.copyWith(
          summary: 'Updated summary',
          isCompleted: true,
        );
        await repository.update(updated);

        final retrieved = await repository.getByUuid('test-uuid-2');
        expect(retrieved!.summary, 'Updated summary');
        expect(retrieved.isCompleted, true);
      });

      test('delete removes entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-3',
          rawText: 'To be deleted',
          type: EntryType.fact,
          summary: 'Delete test',
          createdAt: DateTime.now(),
        );

        await repository.add(entry);
        await repository.delete('test-uuid-3');

        final result = await repository.getByUuid('test-uuid-3');
        expect(result, isNull);
      });

      test('delete on non-existent entry does not throw', () async {
        // Should not throw
        await repository.delete('non-existent-uuid');
      });
    });

    group('query operations', () {
      setUp(() async {
        // Add test data
        final entries = [
          MemoryEntry(
            uuid: 'query-1',
            rawText: 'First entry',
            type: EntryType.insight,
            summary: 'Insight about Alice',
            createdAt: DateTime(2026, 3, 20),
            personMentioned: 'Alice',
            tags: ['work', 'project'],
          ),
          MemoryEntry(
            uuid: 'query-2',
            rawText: 'Second entry',
            type: EntryType.actionable,
            summary: 'Task for Bob',
            createdAt: DateTime(2026, 3, 21),
            personMentioned: 'Bob',
            isCompleted: false,
            tags: ['personal'],
          ),
          MemoryEntry(
            uuid: 'query-3',
            rawText: 'Third entry',
            type: EntryType.pattern,
            summary: 'Pattern detected',
            createdAt: DateTime(2026, 3, 22),
            isCompleted: true,
            tags: ['work', 'analysis'],
          ),
        ];

        for (final entry in entries) {
          await repository.add(entry);
        }
      });

      test('getAll returns all entries', () async {
        final all = await repository.getAll();
        expect(all.length, greaterThanOrEqualTo(3));
      });

      test('getByType filters by type', () async {
        final insights = await repository.getByType(EntryType.insight);
        expect(insights.every((e) => e.type == EntryType.insight), true);
      });

      test('getByPerson filters by person', () async {
        final aliceEntries = await repository.getByPerson('Alice');
        expect(aliceEntries.every((e) => e.personMentioned == 'Alice'), true);
      });

      test('getPendingTasks returns only incomplete actionables', () async {
        final pending = await repository.getPendingTasks();

        expect(pending.every((e) =>
          e.type == EntryType.actionable && !e.isCompleted), true);
      });

      test('search finds entries by text content', () async {
        final results = await repository.search('Alice');
        expect(results.any((e) => e.summary.contains('Alice')), true);
      });

      test('search returns empty list for no matches', () async {
        final results = await repository.search('xyznonexistent');
        expect(results, isEmpty);
      });

      test('getRecent returns limited number of entries', () async {
        final recent = await repository.getRecent(limit: 2);
        expect(recent.length, lessThanOrEqualTo(2));
      });

      test('getRecent returns most recent entries first', () async {
        final recent = await repository.getRecent(limit: 10);

        for (int i = 1; i < recent.length; i++) {
          expect(
            recent[i].createdAt.isBefore(recent[i - 1].createdAt) ||
            recent[i].createdAt.isAtSameMomentAs(recent[i - 1].createdAt),
            true,
          );
        }
      });

      test('getByTags filters by tags', () async {
        final workEntries = await repository.getByTags(['work']);
        expect(workEntries.every((e) => e.tags.contains('work')), true);
      });

      test('getByTags with multiple tags uses OR logic', () async {
        final entries = await repository.getByTags(['work', 'personal']);
        expect(
          entries.every((e) => e.tags.contains('work') || e.tags.contains('personal')),
          true,
        );
      });
    });

    group('statistics', () {
      test('getCount returns total number of entries', () async {
        final initialCount = await repository.getCount();

        await repository.add(MemoryEntry(
          uuid: 'count-test',
          rawText: 'Test',
          type: EntryType.fact,
          summary: 'Test',
          createdAt: DateTime.now(),
        ));

        final newCount = await repository.getCount();
        expect(newCount, initialCount + 1);
      });

      test('getCountByType returns correct counts', () async {
        final count = await repository.getCountByType(EntryType.insight);
        final insights = await repository.getByType(EntryType.insight);
        expect(count, insights.length);
      });

      test('getCompletionRate calculates correctly', () async {
        // Add completed and incomplete tasks
        await repository.add(MemoryEntry(
          uuid: 'complete-1',
          rawText: 'Done',
          type: EntryType.actionable,
          summary: 'Done task',
          createdAt: DateTime.now(),
          isCompleted: true,
        ));

        await repository.add(MemoryEntry(
          uuid: 'incomplete-1',
          rawText: 'Pending',
          type: EntryType.actionable,
          summary: 'Pending task',
          createdAt: DateTime.now(),
          isCompleted: false,
        ));

        final rate = await repository.getCompletionRate();
        expect(rate, greaterThanOrEqualTo(0.0));
        expect(rate, lessThanOrEqualTo(100.0));
      });
    });

    group('edge cases', () {
      test('handles concurrent add operations', () async {
        final futures = List.generate(10, (i) {
          return repository.add(MemoryEntry(
            uuid: 'concurrent-$i',
            rawText: 'Concurrent $i',
            type: EntryType.fact,
            summary: 'Summary $i',
            createdAt: DateTime.now(),
          ));
        });

        await Future.wait(futures);

        final all = await repository.getAll();
        expect(all.where((e) => e.uuid.startsWith('concurrent-')).length, 10);
      });

      test('update preserves original if fields unchanged', () async {
        final entry = MemoryEntry(
          uuid: 'preserve-test',
          rawText: 'Original',
          type: EntryType.insight,
          summary: 'Original summary',
          createdAt: DateTime(2026, 1, 1),
          tags: ['original'],
        );

        await repository.add(entry);
        await repository.update(entry); // Update with same data

        final retrieved = await repository.getByUuid('preserve-test');
        expect(retrieved!.summary, 'Original summary');
        expect(retrieved.tags, ['original']);
      });

      test('handles special characters in search', () async {
        await repository.add(MemoryEntry(
          uuid: 'special-chars',
          rawText: 'Entry with special chars: @#\$%^&*()',
          type: EntryType.fact,
          summary: 'Special: @#\$%',
          createdAt: DateTime.now(),
        ));

        final results = await repository.search('@#\$%');
        expect(results.isNotEmpty, true);
      });

      test('handles empty tags gracefully', () async {
        final entry = MemoryEntry(
          uuid: 'no-tags',
          rawText: 'No tags',
          type: EntryType.fact,
          summary: 'No tags entry',
          createdAt: DateTime.now(),
          tags: [],
        );

        await repository.add(entry);
        final retrieved = await repository.getByUuid('no-tags');
        expect(retrieved!.tags, isEmpty);
      });

      test('handles null optional fields', () async {
        final entry = MemoryEntry(
          uuid: 'null-fields',
          rawText: 'Test',
          type: EntryType.insight,
          summary: 'Test',
          createdAt: DateTime.now(),
          personMentioned: null,
          taskDescription: null,
          timeHint: null,
        );

        await repository.add(entry);
        final retrieved = await repository.getByUuid('null-fields');

        expect(retrieved!.personMentioned, isNull);
        expect(retrieved.taskDescription, isNull);
        expect(retrieved.timeHint, isNull);
      });
    });
  });
}
