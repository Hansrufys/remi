import 'package:flutter_test/flutter_test.dart';
import 'package:remi/data/models/memory_entry.dart';
import 'package:remi/data/repositories/repositories.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MemoryRepository', () {
    late MemoryRepository repository;

    setUp(() async {
      repository = MemoryRepository();
      // Clean up before each test
      await repository.deleteAll();
    });

    tearDown(() async {
      // Clean up after each test
      await repository.deleteAll();
    });

    test('save and retrieve entry', () async {
      final entry = MemoryEntry(
        text: 'Test entry',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
      );

      final id = await repository.save(entry);
      expect(id, greaterThan(0));

      final entries = await repository.getAllEntries();
      expect(entries.length, 1);
      expect(entries.first.text, 'Test entry');
      expect(entries.first.type, EntryType.factPattern);
    });

    test('getRecentEntries returns entries in order', () async {
      await repository.save(MemoryEntry(
        text: 'Entry 1',
        type: EntryType.factPattern,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ));
      await repository.save(MemoryEntry(
        text: 'Entry 2',
        type: EntryType.event,
        createdAt: DateTime.now(),
      ));

      final entries = await repository.getRecentEntries(limit: 10);
      expect(entries.length, 2);
      // Most recent first
      expect(entries.first.text, 'Entry 2');
    });

    test('getEntriesForPerson filters by person', () async {
      await repository.save(MemoryEntry(
        text: 'About Alice',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
        person: 'Alice',
      ));
      await repository.save(MemoryEntry(
        text: 'About Bob',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
        person: 'Bob',
      ));

      final aliceEntries = await repository.getEntriesForPerson('Alice');
      expect(aliceEntries.length, 1);
      expect(aliceEntries.first.person, 'Alice');
    });

    test('getUncompletedTasks returns only pending tasks', () async {
      await repository.save(MemoryEntry(
        text: 'Pending task',
        type: EntryType.task,
        createdAt: DateTime.now(),
        isCompleted: false,
      ));
      await repository.save(MemoryEntry(
        text: 'Completed task',
        type: EntryType.task,
        createdAt: DateTime.now(),
        isCompleted: true,
      ));
      await repository.save(MemoryEntry(
        text: 'Not a task',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
      ));

      final tasks = await repository.getUncompletedTasks();
      expect(tasks.length, 1);
      expect(tasks.first.text, 'Pending task');
    });

    test('searchEntries finds matching entries', () async {
      await repository.save(MemoryEntry(
        text: 'Alice likes coffee',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
      ));
      await repository.save(MemoryEntry(
        text: 'Bob likes tea',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
      ));

      final results = await repository.searchEntries('Alice');
      expect(results.length, 1);
      expect(results.first.text, contains('Alice'));
    });

    test('delete removes entry', () async {
      final id = await repository.save(MemoryEntry(
        text: 'To delete',
        type: EntryType.factPattern,
        createdAt: DateTime.now(),
      ));

      var entries = await repository.getAllEntries();
      expect(entries.length, 1);

      await repository.delete(id);
      entries = await repository.getAllEntries();
      expect(entries.length, 0);
    });

    test('toggleCompletion updates task status', () async {
      final id = await repository.save(MemoryEntry(
        text: 'Task to complete',
        type: EntryType.task,
        createdAt: DateTime.now(),
        isCompleted: false,
      ));

      await repository.toggleCompletion(id, true);

      final tasks = await repository.getUncompletedTasks();
      expect(tasks.length, 0);
    });

    test('updatePriority changes priority', () async {
      final id = await repository.save(MemoryEntry(
        text: 'Task',
        type: EntryType.task,
        createdAt: DateTime.now(),
        priority: 1,
      ));

      await repository.updatePriority(id, 5);

      final entries = await repository.getAllEntries();
      expect(entries.first.priority, 5);
    });
  });

  group('PersonRepository', () {
    late PersonRepository repository;

    setUp(() async {
      repository = PersonRepository();
      // Clean all profiles
      final all = await repository.getAll();
      for (var p in all) {
        await repository.deleteProfile(p.id!);
      }
    });

    test('upsert and findByName', () async {
      final profile = PersonProfile(name: 'Alice', insights: []);
      await repository.upsert(profile);

      final found = await repository.findByName('Alice');
      expect(found, isNotNull);
      expect(found!.name, 'Alice');
    });

    test('getAll returns all profiles', () async {
      await repository.upsert(PersonProfile(name: 'Alice', insights: []));
      await repository.upsert(PersonProfile(name: 'Bob', insights: []));

      final all = await repository.getAll();
      expect(all.length, greaterThanOrEqualTo(2));
    });
  });
}
