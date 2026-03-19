import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/memory_entry.dart';
import '../models/person_profile.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

// ===== Database Singleton =====

class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'remi.db'),
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE memory_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL,
        raw_text TEXT NOT NULL,
        type TEXT NOT NULL,
        summary TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        person_mentioned TEXT,
        tags TEXT,
        task_description TEXT,
        time_hint TEXT,
        insight_detail TEXT,
        is_processing INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 50,
        spino_reaction TEXT,
        spino_notification TEXT,
        remind_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE person_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        insight_notes TEXT,
        insight_dates TEXT,
        last_mentioned_at TEXT,
        created_at TEXT NOT NULL,
        avatar_initial TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_type ON memory_entries (type)');
    await db.execute('CREATE INDEX idx_created ON memory_entries (created_at)');
    await db.execute('CREATE INDEX idx_person ON person_profiles (name)');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE memory_entries ADD COLUMN priority INTEGER NOT NULL DEFAULT 50',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE memory_entries ADD COLUMN spino_reaction TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE memory_entries ADD COLUMN remind_at TEXT',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE memory_entries ADD COLUMN spino_notification TEXT',
      );
    }
    if (oldVersion < 7) {
        // Emergency catch-all for spino_notification if version 6 was created without it
        try {
          await db.execute('ALTER TABLE memory_entries ADD COLUMN spino_notification TEXT');
        } catch (e) {
          debugPrint('Migration notice (may be expected if column exists): $e');
        }
    }
  }
}

// ===== Memory Repository =====

class MemoryRepository {
  static MemoryRepository? _instance;
  static Database? _dbInstance;
  static SupabaseClient? _supabaseInstance;

  MemoryRepository._();

  factory MemoryRepository() {
    _instance ??= MemoryRepository._();
    return _instance!;
  }

  Future<Database> get _db async {
    _dbInstance ??= await AppDatabase.instance;
    return _dbInstance!;
  }

  SupabaseClient? get _supabase {
    _supabaseInstance ??= SupabaseService().isInitialized ? SupabaseService().client : null;
    return _supabaseInstance;
  }

  Future<int> save(MemoryEntry entry) async {
    final db = await _db;
    
    // 1. Sync to Supabase first (if online)
    try {
      if (_supabase != null) {
        await _supabase!.from('memories').upsert(entry.toMap());
      }
    } catch (e) {
      debugPrint('SUPABASE SAVE ERROR: $e');
    }

    // 2. Always save locally for offline responsiveness
    try {
      return await db.insert('memory_entries', entry.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, stack) {
      debugPrint('SQL SAVE ERROR: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }

  Future<List<MemoryEntry>> getAllEntries() async {
    // 1. Try Supabase first
    if (_supabase != null) {
      try {
        final response = await _supabase!.from('memories').select().order('created_at', ascending: true);
        final entries = (response as List).map((m) => MemoryEntry.fromMap(m)).toList();
        // Option: Update local cache here?
        return entries;
      } catch (e) {
        debugPrint('SUPABASE READ ERROR (ALL): $e');
      }
    }

    // 2. Fallback to local
    final db = await _db;
    final rows = await db.query('memory_entries', orderBy: 'created_at ASC');
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<List<MemoryEntry>> getTodayEntries() async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day + 1).toIso8601String();

    if (_supabase != null) {
      try {
        final response = await _supabase!
            .from('memories')
            .select()
            .gte('created_at', start)
            .lt('created_at', end)
            .order('created_at', ascending: true);
        return (response as List).map((m) => MemoryEntry.fromMap(m)).toList();
      } catch (e) {
        debugPrint('SUPABASE READ ERROR (TODAY): $e');
      }
    }

    final db = await _db;
    final rows = await db.query(
      'memory_entries',
      where: 'created_at >= ? AND created_at < ?',
      whereArgs: [start, end],
      orderBy: 'created_at ASC',
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<List<MemoryEntry>> getDailyFeedEntries() async {
    final db = await _db;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day).toIso8601String();
    
    // We want: All entries created today OR incomplete tasks from the past
    final rows = await db.query(
      'memory_entries',
      where: '(created_at >= ?) OR (type = ? AND is_completed = ?)',
      whereArgs: [startOfToday, 'actionable', 0],
      orderBy: 'created_at ASC',
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<List<MemoryEntry>> getRecentEntries({int limit = 50}) async {
    final db = await _db;
    final rows = await db.query(
      'memory_entries',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<List<MemoryEntry>> getEntriesForPerson(String name) async {
    final db = await _db;
    final rows = await db.query(
      'memory_entries',
      where: 'LOWER(person_mentioned) = LOWER(?)',
      whereArgs: [name],
      orderBy: 'created_at ASC',
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<void> toggleCompletion(int entryId, bool isCompleted) async {
    final db = await _db;
    
    // Sync to Supabase
    if (_supabase != null) {
      try {
        final rows = await db.query('memory_entries', where: 'id = ?', whereArgs: [entryId]);
        if (rows.isNotEmpty) {
           final uuid = rows.first['uuid'] as String;
           await _supabase!.from('memories').update({'is_completed': isCompleted}).eq('uuid', uuid);
        }
      } catch (e) {
        debugPrint('SUPABASE TOGGLE ERROR: $e');
      }
    }

    await db.update(
      'memory_entries',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<void> updatePriority(int entryId, int priority) async {
    final db = await _db;
    await db.update(
      'memory_entries',
      {'priority': priority},
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  Future<List<MemoryEntry>> getDailyFeedEntriesSorted() async {
    final db = await _db;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day).toIso8601String();
    final rows = await db.query(
      'memory_entries',
      where: '(created_at >= ?) OR (type = ? AND is_completed = ?)',
      whereArgs: [startOfToday, 'actionable', 0],
      // Sort: uncompleted tasks by priority first, then everything else by time
      orderBy: 'is_completed ASC, priority ASC, created_at ASC',
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<List<MemoryEntry>> getUncompletedTasks() async {
    final db = await _db;
    final rows = await db.query(
      'memory_entries',
      where: "type = 'actionable' AND is_completed = 0",
      orderBy: 'created_at ASC',
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  Future<void> completeAllTasks() async {
    final db = await _db;
    await db.update(
      'memory_entries',
      {'is_completed': 1},
      where: "type = 'actionable' AND is_completed = 0",
    );
  }

  Future<void> delete(int entryId) async {
    final db = await _db;

    if (_supabase != null) {
      try {
        final rows = await db.query('memory_entries', where: 'id = ?', whereArgs: [entryId]);
        if (rows.isNotEmpty) {
          final uuid = rows.first['uuid'] as String;
          await _supabase!.from('memories').delete().eq('uuid', uuid);
        }
      } catch (e) {
        debugPrint('SUPABASE DELETE ERROR: $e');
      }
    }

    await db.delete('memory_entries', where: 'id = ?', whereArgs: [entryId]);
  }

  Future<void> deleteAll() async {
    final db = await _db;
    await db.delete('memory_entries');
  }

  /// Full-text search across all stored entries.
  Future<List<MemoryEntry>> searchEntries(String query) async {
    if (query.trim().isEmpty) return [];
    final db = await _db;
    final q = '%${query.trim().toLowerCase()}%';
    final rows = await db.query(
      'memory_entries',
      where: '''
        LOWER(summary) LIKE ? OR
        LOWER(raw_text) LIKE ? OR
        LOWER(tags) LIKE ? OR
        LOWER(person_mentioned) LIKE ? OR
        LOWER(task_description) LIKE ?
      ''',
      whereArgs: [q, q, q, q, q],
      orderBy: 'created_at DESC',
      limit: 50,
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }

  /// Finds past entries whose summary or tags share at least one meaningful keyword
  /// with [text]. Used for context-chain linking.
  Future<List<MemoryEntry>> findRelatedEntries(String text, {int? excludeId, int limit = 5}) async {
    if (text.trim().isEmpty) return [];
    final db = await _db;
    // Extract keywords longer than 4 chars, skip stopwords
    final stopwords = {'habe', 'ich', 'das', 'die', 'der', 'und', 'oder', 'auch', 'eine', 'einen', 'einem', 'ist', 'sind', 'war', 'wurde', 'kann', 'will', 'soll', 'muss', 'hat', 'haben', 'sein', 'noch', 'mir', 'mich', 'mein', 'dein', 'nicht', 'kein', 'mit', 'von', 'für', 'was', 'wie', 'bei', 'nach', 'über', 'that', 'this', 'with', 'have', 'from', 'they', 'been', 'would'};
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 4 && !stopwords.contains(w)).toSet().take(5).toList();
    if (words.isEmpty) return [];

    final conditions = words.map((_) => '(LOWER(summary) LIKE ? OR LOWER(raw_text) LIKE ?)').join(' OR ');
    final args = words.expand((w) => ['%$w%', '%$w%']).toList();

    String whereClause = conditions;
    final List<Object?> finalArgs = List.from(args);

    if (excludeId != null) {
      whereClause = '($conditions) AND id != ?';
      finalArgs.add(excludeId);
    }

    final rows = await db.query(
      'memory_entries',
      where: whereClause,
      whereArgs: finalArgs,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return rows.map(MemoryEntry.fromMap).toList();
  }
}

// ===== Person Profile Repository =====

class PersonProfileRepository {
  static PersonProfileRepository? _instance;
  static Database? _dbInstance;
  static SupabaseClient? _supabaseInstance;

  PersonProfileRepository._();

  factory PersonProfileRepository() {
    _instance ??= PersonProfileRepository._();
    return _instance!;
  }

  Future<Database> get _db async {
    _dbInstance ??= await AppDatabase.instance;
    return _dbInstance!;
  }

  SupabaseClient? get _supabase {
    _supabaseInstance ??= SupabaseService().isInitialized ? SupabaseService().client : null;
    return _supabaseInstance;
  }

  Future<PersonProfile?> findByName(String name) async {
    final db = await _db;
    final rows = await db.query(
      'person_profiles',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isEmpty ? null : PersonProfile.fromMap(rows.first);
  }

  Future<int> upsert(PersonProfile profile) async {
    // 1. Sync to Supabase
    if (_supabase != null) {
      try {
        await _supabase!.from('people').upsert(profile.toMap());
      } catch (e) {
        debugPrint('SUPABASE PERSON UPSERT ERROR: $e');
      }
    }

    final db = await _db;
    if (profile.id != null) {
      await db.update(
        'person_profiles',
        profile.toMap(),
        where: 'id = ?',
        whereArgs: [profile.id],
      );
      return profile.id!;
    }
    return db.insert('person_profiles', profile.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PersonProfile>> getAll() async {
    if (_supabase != null) {
      try {
        final response = await _supabase!.from('people').select().order('last_mentioned_at', ascending: false);
        return (response as List).map((m) => PersonProfile.fromMap(m)).toList();
      } catch (e) {
        debugPrint('SUPABASE PERSON READ ERROR: $e');
      }
    }

    final db = await _db;
    final rows = await db.query(
      'person_profiles',
      orderBy: 'last_mentioned_at DESC',
    );
    return rows.map(PersonProfile.fromMap).toList();
  }

  Future<PersonProfile?> getById(int id) async {
    final db = await _db;
    final rows = await db.query('person_profiles', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : PersonProfile.fromMap(rows.first);
  }

  Future<void> addInsightToProfile({
    required String personName,
    required String note,
  }) async {
    PersonProfile? profile = await findByName(personName);
    profile ??= PersonProfile(
        uuid: DateTime.now().millisecondsSinceEpoch.toString(),
        name: personName,
        createdAt: DateTime.now(),
        avatarInitial: personName.isNotEmpty ? personName[0].toUpperCase() : '?',
      );
    final updated = profile.copyWithNote(note);
    await upsert(updated);
  }

  Future<void> removeInsightFromProfile(int profileId, int index) async {
    final profile = await getById(profileId);
    if (profile != null) {
      final updated = profile.removeNoteAtIndex(index);
      await upsert(updated);
    }
  }

  Future<void> deleteProfile(int id) async {
    final db = await _db;
    // 1. Find profile to get name
    final profile = await getById(id);
    if (profile != null) {
      // 2. Delete all memories mentioned that person
      await db.delete(
        'memory_entries',
        where: 'LOWER(person_mentioned) = LOWER(?)',
        whereArgs: [profile.name],
      );
    }
    // 3. Delete profile itself
    await db.delete('person_profiles', where: 'id = ?', whereArgs: [id]);
  }
}
