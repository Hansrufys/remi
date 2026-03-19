import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/notification_service.dart';
import '../../data/models/memory_entry.dart';

class EchoSchedulerService {
  final Ref ref;
  final MemoryRepository _memoryRepo = MemoryRepository();
  final NotificationService _notifications = NotificationService();

  EchoSchedulerService(this.ref);

  /// Initializes scheduled echoes like the 9 PM summary
  Future<void> scheduleStandardEchoes() async {
    await _notifications.scheduleDailyNotification(
      id: 99,
      title: 'Your Evening Wrap is ready',
      body: 'Tap to see a summary of your day and tomorrow\'s focus.',
      hour: 21,
      minute: 0,
    );
  }

  /// Checks for "Forgotten Thoughts" — actionable items from previous days
  /// that are still uncompleted.
  Future<void> detectForgottenThoughts() async {
    final allEntries = await _memoryRepo.getAllEntries();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final forgotten = allEntries.where((e) {
      if (e.id == null || e.isCompleted || e.type != EntryType.actionable) return false;
      
      final entryDate = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      return entryDate.isBefore(today);
    }).toList();

    if (forgotten.isNotEmpty) {
      final count = forgotten.length;
      final label = count == 1 ? 'thought' : 'thoughts';
      
      await _notifications.showNotification(
        id: 101,
        title: 'Forgotten $label?',
        body: 'You have $count pending tasks from previous days. Want to clear them?',
      );
    }
  }

  /// Manually trigger a summary of today's activities (can be used for the wrap)
  Future<String> generateDailySummary() async {
    final todayEntries = await _memoryRepo.getTodayEntries();
    if (todayEntries.isEmpty) return 'No memories recorded today.';

    final tasks = todayEntries.where((e) => e.type == EntryType.actionable).length;
    final insights = todayEntries.where((e) => e.type == EntryType.insight).length;

    return 'Today you captured $tasks tasks and $insights insights.';
  }
}

final echoSchedulerProvider = Provider((ref) => EchoSchedulerService(ref));
