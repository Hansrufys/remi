import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/memory_entry.dart';
import '../../data/repositories/repositories.dart';

/// Bottom sheet that shows context-chain entries related to [sourceEntry].
class RelatedEntriesSheet extends StatefulWidget {
  final MemoryEntry sourceEntry;
  const RelatedEntriesSheet({super.key, required this.sourceEntry});

  @override
  State<RelatedEntriesSheet> createState() => _RelatedEntriesSheetState();
}

class _RelatedEntriesSheetState extends State<RelatedEntriesSheet> {
  late Future<List<MemoryEntry>> _futureEntries;

  @override
  void initState() {
    super.initState();
    _futureEntries = MemoryRepository().findRelatedEntries(
      widget.sourceEntry.summary.isNotEmpty
          ? widget.sourceEntry.summary
          : widget.sourceEntry.rawText,
      excludeId: widget.sourceEntry.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: BoxDecoration(
          color: AppColors.of(context).paper,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.of(context).bioAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('↗', style: TextStyle(
                        color: AppColors.of(context).bioAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      )),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('Kontext-Ketten', style: AppTypography.textTheme(context).titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.of(context).charcoal,
                  )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Einträge die mit diesem Thema zusammenhängen',
                style: AppTypography.textTheme(context).bodySmall?.copyWith(color: AppColors.of(context).mutedText),
              ),
            ),
            Divider(color: AppColors.of(context).borderLight),
            Expanded(
              child: FutureBuilder<List<MemoryEntry>>(
                future: _futureEntries,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  final entries = snapshot.data ?? [];
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔗', style: TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            'Noch keine verwandten Einträge.',
                            style: AppTypography.textTheme(context).bodyMedium?.copyWith(color: AppColors.of(context).mutedText),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remi verknüpft deine Gedanken mit der Zeit.',
                            style: AppTypography.textTheme(context).bodySmall?.copyWith(color: AppColors.of(context).mutedText),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => Divider(color: AppColors.of(context).borderLight, height: 1),
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 8, height: 8,
                              margin: const EdgeInsets.only(top: 5, right: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _typeColor(e.type),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.summary.isNotEmpty ? e.summary : e.rawText,
                                    style: AppTypography.textTheme(context).bodyMedium?.copyWith(
                                      color: AppColors.of(context).inkLight,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('dd. MMM yyyy').format(e.createdAt),
                                    style: AppTypography.textTheme(context).bodySmall?.copyWith(color: AppColors.of(context).mutedText),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeColor(EntryType type) => switch (type) {
    EntryType.actionable => AppColors.of(context).charcoal,
    EntryType.insight => AppColors.of(context).bioAccent,
    EntryType.pattern => AppColors.of(context).bioAccent,
    _ => AppColors.of(context).mutedText,
  };
}
