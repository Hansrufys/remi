import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/memory_entry.dart';
import '../../data/repositories/repositories.dart';

final _eveningWrapProvider = FutureProvider<_WrapData>((ref) async {
  final repo = MemoryRepository();
  final entries = await repo.getTodayEntries();
  final tasks = entries.where((e) => e.type == EntryType.actionable).toList();
  final completed = tasks.where((e) => e.isCompleted).toList();
  final forgotten = tasks.where((e) => !e.isCompleted).toList();
  final memories = entries.where((e) => e.type == EntryType.insight).length;
  return _WrapData(
    completedTasks: completed,
    forgottenThoughts: forgotten,
    memoryCount: memories,
  );
});

class _WrapData {
  final List<MemoryEntry> completedTasks;
  final List<MemoryEntry> forgottenThoughts;
  final int memoryCount;
  _WrapData({required this.completedTasks, required this.forgottenThoughts, required this.memoryCount});
}

class EveningWrapScreen extends ConsumerWidget {
  const EveningWrapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(_eveningWrapProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).paper,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).paper,
        title: const Text('Evening Wrap'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: data.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.of(context).bioAccent)),
        error: (_, __) => const Center(child: Text('Could not load summary')),
        data: (wrap) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 28),
                _buildStat(context, '✦ Wins Today', '${wrap.completedTasks.length} tasks completed', AppColors.of(context).bioAccent),
                const SizedBox(height: 12),
                _buildStat(context, '🧠 Memories Saved', '${wrap.memoryCount} people memories', AppColors.of(context).tagInsight),
                const SizedBox(height: 28),
                if (wrap.forgottenThoughts.isNotEmpty) ...[
                  Text('Forgotten Thoughts', style: AppTypography.textTheme(context).titleLarge),
                  const SizedBox(height: 12),
                  Text(
                    'These tasks from today were left unfinished. Reschedule?',
                    style: AppTypography.textTheme(context).bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ...wrap.forgottenThoughts.map((e) => _ForgottenThoughtCard(entry: e)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(greeting, style: AppTypography.textTheme(context).headlineLarge),
        const SizedBox(height: 4),
        Text("Here's your day at a glance.", style: AppTypography.textTheme(context).bodyMedium),
      ],
    );
  }

  Widget _buildStat(BuildContext context, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.textTheme(context).titleMedium)),
          Text(value, style: AppTypography.textTheme(context).labelLarge?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _ForgottenThoughtCard extends StatelessWidget {
  final MemoryEntry entry;
  const _ForgottenThoughtCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).borderLight),
      ),
      child: Row(
        children: [
          Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.of(context).mutedText),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.taskDescription ?? entry.rawText, style: AppTypography.textTheme(context).bodyMedium)),
        ],
      ),
    );
  }
}
