import 'package:flutter_test/flutter_test.dart';
import 'package:remi/features/memory/data/models/memory_entry.dart';
import 'package:remi/features/memory/data/repositories/memory_repository.dart';

void main() {
  group('MemoryRepository', () {
    late MemoryRepository repository;

    setUp(() {
      repository = MemoryRepository();
    });

    group('save', () {
      test('saves a memory entry', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-1',
          rawText: 'This is a test memory',
          summary: 'Test memory summary',
          type: EntryType.factPattern,
          createdAt: DateTime(2024, 1, 1),
        );

        await repository.save(entry);

        final entries = await repository.getAllEntries();
        expect(entries.length, 1);
        expect(entries.first.uuid, 'test-uuid-1');
        expect(entries.first.summary, 'Test memory summary');
      });

      test('saves multiple entries', () async {
        final entry1 = MemoryEntry(
          uuid: 'test-uuid-1',
          rawText: 'First memory',
          summary: 'First summary',
          type: EntryType.factPattern,
          createdAt: DateTime(2024, 1, 1),
        );

        final entry2 = MemoryEntry(
          uuid: 'test-uuid-2',
          rawText: 'Second memory',
          summary: 'Second summary',
          type: EntryType.insight,
          createdAt: DateTime(2024, 1, 2),
        );

        await repository.save(entry1);
        await repository.save(entry2);

        final entries = await repository.getAllEntries();
        expect(entries.length, 2);
      });
    });

    group('getAllEntries', () {
      test('returns empty list when no entries saved', () async {
        final entries = await repository.getAllEntries();
        expect(entries, isEmpty);
      });

      test('returns all saved entries', () async {
        final entry = MemoryEntry(
          uuid: 'test-uuid-1',
          rawText: 'Test memory',
          summary: 'Test summary',
          type: EntryType.actionable,
          createdAt: DateTime(2024, 1, 1),
        );

        await repository.save(entry);
        final entries = await repository.getAllEntries();

        expect(entries.length, 1);
        expect(entries.first.uuid, 'test-uuid-1');
      });
    });
  });

  group('MemoryEntry', () {
    test('creates entry with all required fields', () {
      final entry = MemoryEntry(
        uuid: 'test-uuid',
        rawText: 'Raw text content',
        summary: 'Summary of the memory',
        type: EntryType.factPattern,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(entry.uuid, 'test-uuid');
      expect(entry.rawText, 'Raw text content');
      expect(entry.summary, 'Summary of the memory');
      expect(entry.type, EntryType.factPattern);
    });

    test('EntryType enum has expected values', () {
      expect(EntryType.values, contains(EntryType.actionable));
      expect(EntryType.values, contains(EntryType.insight));
      expect(EntryType.values, contains(EntryType.factPattern));
      expect(EntryType.values, contains(EntryType.event));
      expect(EntryType.values, contains(EntryType.task));
      expect(EntryType.values, contains(EntryType.unknown));
    });

    test('EntryType.factPattern name is correct', () {
      expect(EntryType.factPattern.name, 'fact pattern');
    });
  });
}
