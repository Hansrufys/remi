import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../data/services/gemini_service.dart';
import '../../data/repositories/repositories.dart';
import '../../data/models/memory_entry.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/quick_entry_service.dart';

const _uuid = Uuid();

class MemoryExtractionUseCase {
  final GeminiService _geminiService;
  final MemoryRepository _memoryRepo;
  final PersonProfileRepository _personRepo;
  final QuickEntryService _quickEntry;
  final NotificationService _notifications = NotificationService();
  final bool _isIncognito;

  MemoryExtractionUseCase({
    required GeminiService geminiService,
    required MemoryRepository memoryRepo,
    required PersonProfileRepository personRepo,
    required QuickEntryService quickEntry,
    bool isIncognito = false,
  })  : _geminiService = geminiService,
        _memoryRepo = memoryRepo,
        _personRepo = personRepo,
        _quickEntry = quickEntry,
        _isIncognito = isIncognito;

  Future<List<MemoryEntry>> execute(String rawText) async {
    debugPrint('Executing MemoryExtractionUseCase for: "$rawText"');

    try {
      final incompleteTasks = await _memoryRepo.getUncompletedTasks();
      final contextTasks = incompleteTasks.map((t) => {
        'task_description': t.taskDescription ?? t.summary,
      }).toList();

      final recentPeople = await _personRepo.getAll();
      final personContext = recentPeople.take(10).map((p) => p.name).toList();

      final results = await _geminiService.extractMemory(
        rawText, 
        contextTasks: contextTasks,
        personContext: personContext,
      );

      debugPrint('AI Extracted \${results.length} entities');
      final List<MemoryEntry> createdEntries = [];
      final Set<String> seenSummaries = {};
      bool shouldVibrate = false;

      for (final result in results) {
        if (result.globalAction == 'complete_all_tasks') {
          await _memoryRepo.completeAllTasks();
          shouldVibrate = true;
        }

        if (result.type == 'unknown') continue;
        
        final summaryKey = result.summary.toLowerCase().trim();
        if (summaryKey.isEmpty || seenSummaries.contains(summaryKey)) continue;
        seenSummaries.add(summaryKey);

        final entryType = switch (result.type) {
          'actionable' => EntryType.actionable,
          'insight' => EntryType.insight,
          'pattern' => EntryType.pattern,
          _ => EntryType.unknown,
        };

        final entry = MemoryEntry(
          uuid: _uuid.v4(),
          rawText: rawText,
          type: entryType,
          summary: result.summary,
          tags: [], 
          personMentioned: result.personName,
          createdAt: DateTime.now(),
          isCompleted: false,
          taskDescription: result.taskDescription,
          timeHint: null, 
          insightDetail: result.insightDetail,
          isProcessing: false,
          spinoReaction: result.spinoReaction,
          spinoNotification: result.spinoNotification,
          remindAt: result.remindAt != null ? DateTime.tryParse(result.remindAt!) : null,
        );

        if (_isIncognito) {
          createdEntries.add(entry);
          continue;
        }

        final entryId = await _memoryRepo.save(entry);
        final entryWithId = entry.copyWith(id: entryId);
        createdEntries.add(entryWithId);

        if (entryWithId.remindAt != null) {
          await _notifications.scheduleMemoryReminder(entryWithId);
        } else if (entryType == EntryType.actionable && entryId > 0) {
          await _notifications.scheduleNudge(
            id: entryId,
            title: 'Erinnerung',
            body: 'Offen: "\${entry.taskDescription ?? entry.summary}"',
            delayInHours: 3,
          );
        }

        if (result.personName != null && result.personName!.isNotEmpty) {
          await _personRepo.addInsightToProfile(
            personName: result.personName!,
            note: result.insightDetail ?? result.summary,
          );
        }

        if (result.spinoReaction == 'pin' || result.spinoReaction == 'catch') {
          shouldVibrate = true;
        }
      }

      if (shouldVibrate) {
        HapticFeedback.mediumImpact();
      }

      if (_isIncognito) return createdEntries;

      if (createdEntries.isNotEmpty) {
        try {
          final relevantMemory = await _getMostRelevantMemory(createdEntries.last);
          final uncompletedTasks = await _memoryRepo.getUncompletedTasks();
          final allMemories = await _memoryRepo.getAllEntries(); 
          final todayCount = allMemories.where((m) => DateUtils.isSameDay(m.createdAt, DateTime.now())).length;

          await _quickEntry.updateWidgetData(
            tasks: uncompletedTasks.length,
            memories: todayCount,
            latestMemory: relevantMemory,
          );
        } catch (e) {
          debugPrint('Failed to update widget: \$e');
        }
      }

      return createdEntries;
    } catch (e, stack) {
      debugPrint('CRITICAL UseCase Failure: \$e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Future<String?> _getMostRelevantMemory(MemoryEntry justSaved) async {
    final uncompleted = await _memoryRepo.getUncompletedTasks();
    uncompleted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (uncompleted.isNotEmpty) {
      final task = uncompleted.first;
      return "Task: \${task.taskDescription ?? task.summary}";
    }

    final all = await _memoryRepo.getAllEntries();
    final socialKeywords = [
      'geburtstag', 'birthday', 'geschenk', 'besuch', 'treffen', 'party', 
      'hochzeit', 'jubilum', 'event', 'termin', 'verabredung'
    ];
    final upcomingSocial = all.where((m) => 
      m.type == EntryType.insight && 
      socialKeywords.any((kw) => m.summary.toLowerCase().contains(kw))
    ).toList();

    if (upcomingSocial.isNotEmpty) {
      upcomingSocial.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return upcomingSocial.first.summary;
    }

    return justSaved.insightDetail ?? justSaved.taskDescription ?? justSaved.summary;
  }
}
