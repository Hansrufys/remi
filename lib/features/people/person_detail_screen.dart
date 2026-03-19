import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/memory_entry.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/core_widgets.dart';
import '../../data/models/person_profile.dart';
import '../../data/repositories/repositories.dart';

final personDetailProvider =
    FutureProvider.family<PersonProfile?, String>((ref, id) async {
  final parsedId = int.tryParse(id);
  if (parsedId == null) return null;
  return PersonProfileRepository().getById(parsedId);
});

class PersonDetailScreen extends ConsumerStatefulWidget {
  final String personId;
  const PersonDetailScreen({super.key, required this.personId});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  bool _processing = false;
  bool _isInputFocused = false;

  @override
  void initState() {
    super.initState();
    _inputFocusNode.addListener(() {
      setState(() {
        _isInputFocused = _inputFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _processManualInput(PersonProfile profile) async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _processing = true);
    final gemini = ref.read(geminiServiceProvider);
    
    try {
      final insights = await gemini.batchExtractPersonInsights(
        personName: profile.name,
        rawText: text,
      );

      if (insights.isNotEmpty) {
        final memRepo = ref.read(memoryRepoProvider);
        final personRepo = ref.read(personRepoProvider);

        for (final insight in insights) {
          // 1. Save as general memory entry
          final entry = MemoryEntry(
            uuid: const Uuid().v4(),
            rawText: insight,
            summary: insight,
            type: EntryType.insight,
            tags: ['Handmade'],
            personMentioned: profile.name,
            createdAt: DateTime.now(),
            isCompleted: false,
            isProcessing: false,
          );
          await memRepo.save(entry);

          // 2. Add to person profile
          await personRepo.addInsightToProfile(
            personName: profile.name,
            note: insight,
          );
        }

        _inputController.clear();
        ref.invalidate(personDetailProvider(widget.personId));
        ref.invalidate(memoryEntriesProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${insights.length} neue Erinnerungen gespeichert.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = ref.watch(personDetailProvider(widget.personId));

    return Scaffold(
      backgroundColor: AppColors.of(context).paper,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).paper,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.errorRed),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _confirmDelete(context, ref);
            },
            tooltip: 'Purge memory',
          ),
        ],
      ),
      body: person.when(
        loading: () => Center(child: CircularProgressIndicator(color: AppColors.of(context).bioAccent)),
        error: (e, _) => const Center(child: Text('Profile not found')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          return _buildProfile(context, profile);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, PersonProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarInitial(label: profile.avatarInitial ?? profile.name, size: 56),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name, style: AppTypography.textTheme(context).headlineMedium),
                  Text(
                    '${profile.insightNotes.length} memories saved',
                    style: AppTypography.marginMeta(context).copyWith(color: AppColors.of(context).bioAccent),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          _buildManualInputArea(context, profile),
          
          const SizedBox(height: 40),
          Text('Erinnerungen', style: AppTypography.textTheme(context).titleLarge),
          const SizedBox(height: 12),
          // Show notes
          if (profile.insightNotes.isEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 12),
               child: Text('Noch keine Erinnerungen vorhanden.', 
                 style: TextStyle(color: AppColors.of(context).mutedText, fontStyle: FontStyle.italic)),
             ),
          ...List.generate(profile.insightNotes.length, (i) {
            final note = profile.insightNotes[i];
            final date = i < profile.insightDates.length
                ? profile.insightDates[i]
                : DateTime.now();
            return _WhisperNoteCard(
              note: note, 
              date: date,
              onDelete: () async {
                await PersonProfileRepository().removeInsightFromProfile(
                  int.parse(widget.personId), 
                  i,
                );
                ref.invalidate(personDetailProvider(widget.personId));
              },
            );
          }).reversed.take(20),
        ],
      ),
    );
  }

  Widget _buildManualInputArea(BuildContext context, PersonProfile profile) {
    final colors = AppColors.of(context);
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: _isInputFocused 
                ? [colors.bioAccent.withValues(alpha: 0.12), colors.paper]
                : [colors.bioAccent.withValues(alpha: 0.06), colors.paper.withValues(alpha: 0.5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: _isInputFocused ? [
              BoxShadow(
                color: colors.bioAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : [],
            border: Border.all(
              color: _isInputFocused 
                ? colors.bioAccent.withValues(alpha: 0.3)
                : colors.glassBorder.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: GlassPill(
            padding: const EdgeInsets.all(22),
            borderRadius: BorderRadius.circular(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const PulseDot(size: 6),
                    const SizedBox(width: 10),
                    Text('Wissen hinzufügen', 
                      style: AppTypography.textTheme(context).labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 12,
                      )),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.bioAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('AI SYNC',
                        style: AppTypography.textTheme(context).labelSmall?.copyWith(
                          color: colors.bioAccent,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        )),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _inputController,
                  focusNode: _inputFocusNode,
                  maxLines: null,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Was gibt es Neues über ${profile.name}?',
                    hintStyle: AppTypography.handwritten(context).copyWith(
                      color: colors.mutedText.withValues(alpha: 0.4),
                      fontSize: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTypography.handwritten(context).copyWith(
                    fontSize: 24,
                    height: 1.2,
                    color: colors.charcoal,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_processing)
                      PulseDot(size: 12, color: colors.bioAccent)
                    else
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _processManualInput(profile);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isInputFocused ? colors.charcoal : colors.charcoal.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: _isInputFocused ? [
                              BoxShadow(
                                color: colors.charcoal.withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ] : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                              const SizedBox(width: 10),
                              Text('Speichern', 
                                style: AppTypography.textTheme(context).labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                )),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).paper,
        title: const Text('Purge Memory?'),
        content: const Text(
          'All memories about this person will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: const Text('Purge', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final parsedId = int.tryParse(widget.personId);
      if (parsedId != null) {
        await PersonProfileRepository().deleteProfile(parsedId);
        ref.invalidate(allPeopleProvider);
        ref.invalidate(memoryEntriesProvider);
        if (context.mounted) context.pop();
      }
    }
  }
}

class _WhisperNoteCard extends StatelessWidget {
  final String note;
  final DateTime date;
  final VoidCallback? onDelete;
  const _WhisperNoteCard({required this.note, required this.date, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDeleteMenu(context);
      },
      child: GlassPill(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(note, style: AppTypography.textTheme(context).bodyMedium),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDate(date),
              style: AppTypography.marginMeta(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.of(context).borderLight, borderRadius: BorderRadius.circular(2))),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.errorRed),
              title: const Text('Erinnerung löschen', style: TextStyle(color: AppColors.errorRed)),
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

  String _formatDate(DateTime d) => '${d.day}/${d.month}';
}
