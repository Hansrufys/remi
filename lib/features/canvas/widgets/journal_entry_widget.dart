import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../../data/models/memory_entry.dart';
import '../../memory/related_entries_sheet.dart';

// ===== Animated Entry Wrapper =====
// Each card slides in + fades in from the bottom on first render.

class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  const _AnimatedEntry({required this.child});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ===== Journal Entry Widget =====

class JournalEntryWidget extends StatelessWidget {
  final MemoryEntry entry;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onDelete;

  const JournalEntryWidget({
    super.key,
    required this.entry,
    this.onCheckboxChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _AnimatedEntry(
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.heavyImpact();
          _showDeleteMenu(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            switch (entry.type) {
              EntryType.actionable => _ActionableCard(
                  entry: entry,
                  onCheckboxChanged: onCheckboxChanged,
                ),
              EntryType.insight => _InsightCard(entry: entry),
              EntryType.pattern => _PatternCard(entry: entry),
              _ => _UnknownCard(entry: entry),
            },
            // Context-chain button safely below the tags
            GestureDetector(
              onTap: () => _showRelatedEntries(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 0, 12),
                child: Text(
                  '↗ Kontexte',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.of(context).mutedText.withValues(alpha: 0.5),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRelatedEntries(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RelatedEntriesSheet(sourceEntry: entry),
    );
  }

  void _showDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.of(context).borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              title: const Text('Eintrag löschen', style: TextStyle(color: AppColors.errorRed)),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ===== Actionable Card (checkbox task) =====

class _ActionableCard extends StatefulWidget {
  final MemoryEntry entry;
  final ValueChanged<bool?>? onCheckboxChanged;

  const _ActionableCard({required this.entry, this.onCheckboxChanged});

  @override
  State<_ActionableCard> createState() => _ActionableCardState();
}

class _ActionableCardState extends State<_ActionableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.88, end: 1.05)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 60),
    ]).animate(_bounceCtrl);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  void _handleCheckboxChanged(bool? val) {
    if (val == true) {
      HapticFeedback.mediumImpact();
      _bounceCtrl.forward(from: 0.0);
    } else {
      HapticFeedback.selectionClick();
    }
    widget.onCheckboxChanged?.call(val);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceAnim,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: widget.entry.isCompleted,
                    onChanged: _handleCheckboxChanged,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    style: AppTypography.handwritten(context).copyWith(
                      decoration: widget.entry.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppColors.of(context).mutedText,
                      color: widget.entry.isCompleted
                          ? AppColors.of(context).mutedText
                          : AppColors.of(context).charcoal,
                    ),
                    child: Text(
                      widget.entry.taskDescription ?? widget.entry.rawText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _IntelligenceMargin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.entry.personMentioned != null && widget.entry.personMentioned!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: AvatarInitial(label: widget.entry.personMentioned!, size: 24),
                  ),
                if (widget.entry.timeHint != null)
                  Text(widget.entry.timeHint!, style: AppTypography.marginMeta(context)),
                const SizedBox(height: 2),
                TagChip(
                  label: 'Task',
                  color: AppColors.of(context).tagActionable,
                  icon: Icons.radio_button_unchecked,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


// ===== Insight Card (person memory) =====

class _InsightCard extends StatelessWidget {
  final MemoryEntry entry;
  const _InsightCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final person = entry.personMentioned;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            entry.summary.isNotEmpty ? entry.summary : entry.rawText,
            style: AppTypography.handwritten(context),
          ),
        ),
        const SizedBox(width: 8),
        _IntelligenceMargin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (person != null && person.isNotEmpty)
                AvatarInitial(label: person, size: 24),
              const SizedBox(height: 4),
              Text('Memory', style: AppTypography.marginMeta(context)),
              const SizedBox(height: 2),
              TagChip(
                label: 'Insight',
                color: AppColors.of(context).tagInsight,
                icon: Icons.auto_awesome,
              ),
            ],
          ),
        ),
      ],
    );
  }
}


// ===== Unknown / General Card =====

class _UnknownCard extends StatelessWidget {
  final MemoryEntry entry;
  const _UnknownCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            entry.summary.isNotEmpty ? entry.summary : entry.rawText,
            style: AppTypography.handwritten(context),
          ),
        ),
        const SizedBox(width: 8),
        _IntelligenceMargin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (entry.personMentioned != null && entry.personMentioned!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: AvatarInitial(label: entry.personMentioned!, size: 24),
                ),
              Text(
                _formatTime(entry.createdAt),
                style: AppTypography.marginMeta(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ===== Intelligence Margin Column =====

class _IntelligenceMargin extends StatelessWidget {
  final Widget child;
  const _IntelligenceMargin({required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: Align(
        alignment: Alignment.topRight,
        child: child,
      ),
    );
  }
}

// ===== Pattern Card (AI-detected behavioral pattern) =====

class _PatternCard extends StatelessWidget {
  final MemoryEntry entry;
  const _PatternCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.of(context).bioAccent.withValues(alpha: 0.08),
            AppColors.of(context).bioPulse.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.of(context).bioAccent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.of(context).bioAccent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✦', style: TextStyle(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Remi hat ein Muster erkannt',
                  style: TextStyle(
                    color: AppColors.of(context).bioAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.summary,
                  style: AppTypography.textTheme(context).bodyMedium?.copyWith(
                    color: AppColors.of(context).charcoal.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


