import 'dart:convert';
import 'package:flutter/material.dart' show Color, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:uuid/uuid.dart';
import '../models/memory_entry.dart';
import '../repositories/repositories.dart';
import '../../core/env/app_env.dart';

/// Task identifiers used in WorkManager scheduling
const kSortTaskName = 'remi.organize_thoughts';
const kPatternTaskName = 'remi.pattern_detection';

/// Entry point called by WorkManager in a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kSortTaskName) {
      await _runOrganizer();
    } else if (taskName == kPatternTaskName) {
      await _runPatternDetection();
    }
    return Future.value(true);
  });
}

// ===== Daily Organizer (priority sort + digest) =====

Future<void> _runOrganizer() async {
  try {
    final apiKey = await AppEnv.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) return;

    final repo = MemoryRepository();
    final entries = await repo.getDailyFeedEntries();
    if (entries.isEmpty) return;

    final entryList = entries
        .asMap()
        .entries
        .map((e) =>
            'ID:${e.value.id} [${e.value.type.name}] "${e.value.summary.isEmpty ? e.value.rawText : e.value.summary}"'
            '${e.value.isCompleted ? " (erledigt)" : ""}')
        .join('\n');

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {
            'role': 'system',
            'content': '''
Du bist ein stiller Hintergrund-Assistent für die App "Remi". 
Sortiere die folgenden Notizen nach Dringlichkeit.
Antworte NUR mit: {"sorted_ids": [1, 5, 2, ...], "digest": "<1-2 Satz Zusammenfassung der wichtigsten offenen Punkte auf Deutsch>"}
NUR RAW JSON.
'''
          },
          {
            'role': 'user',
            'content': 'Sortiere:\n$entryList',
          },
        ],
        'temperature': 0.1,
        'max_tokens': 512,
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    final clean = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final parsed = jsonDecode(clean) as Map<String, dynamic>;

    final sortedIds = List<int>.from(parsed['sorted_ids'] as List? ?? []);
    for (var i = 0; i < sortedIds.length; i++) {
      await repo.updatePriority(sortedIds[i], i + 1);
    }

    final openTasks = entries
        .where((e) => e.type.name == 'actionable' && !e.isCompleted)
        .toList();
    if (openTasks.isEmpty) return;

    final digest = parsed['digest'] as String? ??
        '${openTasks.length} offene Aufgabe${openTasks.length > 1 ? "n" : ""} warten auf dich.';

    await _sendNotification(9999, '🧠 Remi hat deine Gedanken sortiert', digest);
  } catch (_) {}
}

// ===== Weekly Pattern Detection =====

Future<void> _runPatternDetection() async {
  try {
    final apiKey = await AppEnv.getGeminiApiKey();
    if (apiKey == null || apiKey.isEmpty) return;

    final repo = MemoryRepository();
    final entries = await repo.getRecentEntries(limit: 100);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final weekEntries = entries.where((e) => e.createdAt.isAfter(cutoff)).toList();
    if (weekEntries.length < 5) return;

    final entryList = weekEntries
        .map((e) =>
            '[${e.type.name}] ${e.createdAt.day}.${e.createdAt.month} "${e.summary.isEmpty ? e.rawText : e.summary}"')
        .join('\n');

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {
            'role': 'system',
            'content': '''
Du analysierst die letzten 7 Tage Notizen eines Nutzers und erkennst Muster.
Finde 1-3 konkrete Muster. Formuliere sie als persönliche, freundliche Beobachtungen auf Deutsch.
Antworte NUR mit JSON: {"patterns": ["<Muster 1>", "<Muster 2>"]}
Beispiele:
- "Du vergisst oft abends deine Sport-Aufgaben — vielleicht morgens planen?"
- "Du erwähnst Lena regelmäßig — scheint eine wichtige Person zu sein."
NUR RAW JSON.
'''
          },
          {
            'role': 'user',
            'content': 'Analysiere diese Woche:\n$entryList',
          },
        ],
        'temperature': 0.4,
        'max_tokens': 400,
      }),
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;
    final clean = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final parsed = jsonDecode(clean) as Map<String, dynamic>;
    final patterns = List<String>.from(parsed['patterns'] as List? ?? []);

    if (patterns.isEmpty) return;

    const uuidGen = Uuid();
    for (final pattern in patterns) {
      final entry = MemoryEntry(
        uuid: uuidGen.v4(),
        rawText: pattern,
        type: EntryType.pattern,
        summary: pattern,
        tags: ['🔍 Muster'],
        createdAt: DateTime.now(),
        isCompleted: false,
        isProcessing: false,
      );
      await repo.save(entry);
    }

    await _sendNotification(
      9998,
      '🔍 Remi hat ein Muster erkannt',
      patterns.first,
    );
  } catch (_) {}
}

// ===== Shared notification helper =====

Future<void> _sendNotification(int id, String title, String body) async {
  final notifications = FlutterLocalNotificationsPlugin();
  await notifications.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
    ),
  );
  await notifications.show(
    id,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'remi_digest',
        'Tages-Digest',
        channelDescription: 'KI-Zusammenfassungen und Muster',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_notification',
        color: const Color(0xFF757575),
        styleInformation: BigTextStyleInformation(body),
      ),
    ),
  );
}

/// Register all background tasks (call from main.dart on every launch)
Future<void> registerBackgroundOrganizer() async {
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // Daily: sort thoughts + send digest
  await Workmanager().registerPeriodicTask(
    kSortTaskName,
    kSortTaskName,
    frequency: const Duration(hours: 4),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

  // Daily (data check): detect behavioral patterns when enough data exists
  await Workmanager().registerPeriodicTask(
    kPatternTaskName,
    kPatternTaskName,
    frequency: const Duration(days: 1),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresBatteryNotLow: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}
