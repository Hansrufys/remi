import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../data/models/memory_entry.dart';
import '../../../data/services/quick_entry_service.dart';

class DailyPulseBar extends ConsumerStatefulWidget {
  final List<MemoryEntry> entries;
  const DailyPulseBar({super.key, required this.entries});

  @override
  ConsumerState<DailyPulseBar> createState() => _DailyPulseBarState();
}

class _DailyPulseBarState extends ConsumerState<DailyPulseBar> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateWidgetData();
  }

  void _updateWidgetData() {
    final now = DateTime.now();
    final todayEntries = widget.entries.where((e) {
      return e.createdAt.year == now.year &&
          e.createdAt.month == now.month &&
          e.createdAt.day == now.day;
    }).toList();

    final taskCount = todayEntries.where((e) => e.type == EntryType.actionable).length;
    final memoryCount = todayEntries.where((e) => e.type == EntryType.insight).length;

    ref.read(quickEntryProvider).updateWidgetData(
      tasks: taskCount,
      memories: memoryCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayEntries = widget.entries.where((e) {
      return e.createdAt.year == now.year &&
          e.createdAt.month == now.month &&
          e.createdAt.day == now.day;
    }).toList();

    final taskCount = todayEntries.where((e) => e.type == EntryType.actionable).length;
    final memoryCount = todayEntries.where((e) => e.type == EntryType.insight).length;

    final focusLabel = taskCount >= 5 ? 'High' : taskCount >= 2 ? 'Medium' : 'Low';

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: GlassPill(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PulseStat(
              icon: '✦',
              iconColor: AppColors.of(context).bioAccent,
              label: 'Daily',
            ),
            _divider(context),
            _PulseStat(label: 'Tasks', value: '$taskCount'),
            _divider(context),
            _PulseStat(label: 'Memories', value: '$memoryCount'),
            _divider(context),
            _PulseStat(label: 'Focus', value: focusLabel),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Container(width: 1, height: 14, color: AppColors.of(context).borderLight),
  );
}

class _PulseStat extends StatelessWidget {
  final String? icon;
  final Color? iconColor;
  final String label;
  final String? value;

  const _PulseStat({
    this.icon,
    this.iconColor,
    required this.label,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Text(
            icon!,
            style: TextStyle(
              color: iconColor ?? AppColors.of(context).bioAccent,
              fontSize: 12,
            ),
          ),
        if (icon == null) ...[
          Text(label, style: AppTypography.textTheme(context).labelMedium),
          const SizedBox(width: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.4),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: Text(
              value ?? '',
              key: ValueKey(value),
              style: AppTypography.textTheme(context).labelLarge,
            ),
          ),
        ] else
          const SizedBox(width: 4),
        if (icon != null)
          Text(label,
              style: AppTypography.textTheme(context).labelLarge?.copyWith(
                color: AppColors.of(context).charcoal,
              )),
      ],
    );
  }
}
