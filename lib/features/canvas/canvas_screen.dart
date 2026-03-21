import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/core_widgets.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/memory_entry.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/notification_service.dart';
import '../../features/memory/memory_extraction_use_case.dart';
import '../../features/memory/second_brain_popup.dart';
import '../../data/services/quick_entry_service.dart';
import '../../features/voice/voice_input_notifier.dart';
import '../voice/pulse_button.dart';
import 'widgets/daily_pulse_bar.dart';
import 'widgets/journal_entry_widget.dart';

// ===== Providers =====

// The memoryEntriesProvider is now centralized in app_providers.dart
// The _memoryRepoProvider is now centralized in app_providers.dart
// The _personRepoProvider is now centralized in app_providers.dart

// ===== Canvas Screen =====

class CanvasScreen extends ConsumerStatefulWidget {
  final bool isQuickRecord;
  const CanvasScreen({super.key, this.isQuickRecord = false});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final _textController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _searchFocus = FocusNode();
  bool _isTyping = false;
  bool _hasAutoStarted = false;
  bool _isExtracting = false;
  String _lastTranscript = '';
  bool _searchMode = false;
  List<MemoryEntry>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _handleAutoStart();
  }

  @override
  void didUpdateWidget(CanvasScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isQuickRecord && !oldWidget.isQuickRecord) {
      _hasAutoStarted = false; // Reset so it can trigger again
      _handleAutoStart();
    }
  }

  void _handleAutoStart() {
    if (widget.isQuickRecord && !_hasAutoStarted) {
      _hasAutoStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVoiceToggle();
      });
    }
  }

  Future<void> _processText(String text) async {
    debugPrint('CanvasScreen: Processing text: "$text"');
    if (text.trim().isEmpty) {
      debugPrint('CanvasScreen: Text is empty, skipping.');
      return;
    }
    _textController.clear();
    setState(() => _isTyping = false);
    _focusNode.unfocus();

    try {
      final gemini = ref.read(geminiServiceProvider);
      final memRepo = ref.read(memoryRepoProvider);
      final personRepo = ref.read(personRepoProvider);
      final isIncognito = ref.read(incognitoProvider);

      final quickEntry = ref.read(quickEntryProvider);

      final useCase = MemoryExtractionUseCase(
        geminiService: gemini,
        memoryRepo: memRepo,
        personRepo: personRepo,
        quickEntry: quickEntry,
        isIncognito: isIncognito,
      );

      await useCase.execute(text);
      
      // Update widget with new data after saving
      final entries = await memRepo.getRecentEntries(limit: 10);
      final taskCount = entries.where((e) => e.type == EntryType.actionable && !e.isCompleted).length;
      final memoryCount = entries.where((e) => e.type == EntryType.insight).length;
      final latestMemory = entries.isNotEmpty ? entries.first.summary : null;
      
      quickEntry.updateWidgetData(
        tasks: taskCount,
        memories: memoryCount,
        latestMemory: latestMemory,
      );
    } catch (e) {
      debugPrint('Error during text extraction: $e');
    } finally {
      ref.invalidate(memoryEntriesProvider);
      ref.invalidate(allPeopleProvider);

      // Scroll to bottom on new entry
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Future<void> _handleVoiceToggle() async {
    HapticFeedback.selectionClick();
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    final voiceState = ref.read(voiceInputProvider);

    if (voiceState.status == VoiceState.listening) {
      final text = await voiceNotifier.stopListening();
      if (text != null && text.isNotEmpty && !_isExtracting) {
        setState(() {
          _isExtracting = true;
          _lastTranscript = text;
        });
        await _processText(text);
        if (mounted) {
          setState(() {
            _isExtracting = false;
            _lastTranscript = '';
          });
        }
      }
    } else {
      await voiceNotifier.startListening();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to voice state transitions to auto-submit text when it finishes capturing
    ref.listen<VoiceInputState>(voiceInputProvider, (previous, next) {
      if (previous?.status == VoiceState.listening &&
          next.status == VoiceState.idle &&
          next.transcript.isNotEmpty &&
          !_isExtracting) {
        
        final txt = next.transcript;
        // 1. Immediately clear the UI transcript so the gray duplicate disappears
        ref.read(voiceInputProvider.notifier).resetState();
        
        // 2. Submit the extracted text to Gemini
        if (txt.isNotEmpty) {
          setState(() {
            _isExtracting = true;
            _lastTranscript = txt;
          });
          _processText(txt).whenComplete(() {
            if (mounted) {
              setState(() {
                _isExtracting = false;
                _lastTranscript = '';
              });
            }
          });
        }
      }
    });

    final entries = ref.watch(memoryEntriesProvider);
    final voiceState = ref.watch(voiceInputProvider);
    final today = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.of(context).paper,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _CanvasHeader(
              today: today,
              isSearchActive: _searchMode,
              onSearchTap: _toggleSearch,
            ),

            // ── Search Bar (collapsible) ─────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: _searchMode ? _buildSearchBar() : const SizedBox.shrink(),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _focusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: _searchResults != null
                    ? _buildSearchResultsFeed(_searchResults!, voiceState)
                    : entries.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            color: AppColors.of(context).bioAccent,
                            strokeWidth: 1.5,
                          ),
                        ),
                        error: (e, _) => Center(
                          child: Text('Could not load entries',
                              style: TextStyle(color: AppColors.of(context).mutedText)),
                        ),
                        data: (list) {
                          if (list.isEmpty && !_isTyping && !_searchMode) {
                            return _buildEmptyState();
                          }
                          return _buildJournalFeed(list, voiceState);
                        },
                      ),
              ),
            ),

            // ── Daily Pulse + Pulse Button ───────────────────────────
            const SizedBox(height: 8),
            entries.maybeWhen(
              data: (list) => DailyPulseBar(entries: list),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                PulseButton(
                  voiceState: voiceState.status,
                  onTap: _handleVoiceToggle,
                ),
                // Show a submit button when typing
                if (_isTyping)
                  Positioned(
                    right: 24,
                    child: GestureDetector(
                      onTap: () => _processText(_textController.text),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.of(context).charcoal,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalFeed(List<MemoryEntry> entries, VoiceInputState voiceState) {
    // We have: Entries (X), Transcript (0 or 1), Freeform Input (1)
    final bool hasTranscript = voiceState.transcript.isNotEmpty;
    final int transcriptCount = hasTranscript ? 1 : 0;
    final int itemCount = entries.length + transcriptCount + 1;

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        // 1. Render all saved Memory Entries
        if (index < entries.length) {
          final entry = entries[index];
          return JournalEntryWidget(
            entry: entry,
            onCheckboxChanged: (val) async {
              if (val != null && entry.id != null) {
                await MemoryRepository().toggleCompletion(entry.id!, val);
                if (val == true) {
                  await NotificationService().cancelNotification(entry.id!);
                }
                ref.invalidate(memoryEntriesProvider);
              }
            },
            onDelete: () async {
              if (entry.id != null) {
                await MemoryRepository().delete(entry.id!);
                await NotificationService().cancelNotification(entry.id!);
                ref.invalidate(memoryEntriesProvider);
              }
            },
          );
        }

        // 2. Render Live Transcript Voice Note (if active)
        if ((hasTranscript || _isExtracting) && index == entries.length) {
          return _LiveTranscriptRow(
            text: _isExtracting ? _lastTranscript : voiceState.transcript,
            isProcessing: _isExtracting,
          );
        }

        // 3. Render Freeform text input at the very bottom
        return _buildFreeformInput();
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: AppColors.of(context).bioAccent.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Noch keine Gedanken hier...',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme(context).headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.of(context).charcoal,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Erzähl mir einfach, was dich gerade beschäftigt oder was du nicht vergessen willst.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme(context).bodyLarge?.copyWith(
                color: AppColors.of(context).mutedText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            const PulseDot(size: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeformInput() {
    final hasText = _textController.text.isNotEmpty;
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 120, left: 8, right: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isTyping
              ? [
                  BoxShadow(
                    color: colors.bioAccent.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: GlassPill(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: BorderRadius.circular(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  onTap: () {
                    if (!_isTyping) setState(() => _isTyping = true);
                  },
                  onChanged: (val) {
                    final nowHasText = val.isNotEmpty;
                    if (nowHasText != hasText) setState(() {});
                    if (val.isNotEmpty && !_isTyping) setState(() => _isTyping = true);
                    if (val.isEmpty && _isTyping) setState(() => _isTyping = false);
                  },
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  style: AppTypography.textTheme(context).bodyLarge?.copyWith(
                    fontSize: 16,
                    color: colors.charcoal,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Was beschäftigt dich gerade?',
                    hintStyle: AppTypography.textTheme(context).bodyLarge?.copyWith(
                      color: colors.mutedText.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedScale(
                scale: hasText ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                child: GestureDetector(
                  onTap: hasText ? () => _processText(_textController.text) : null,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.charcoal,
                      boxShadow: [
                        BoxShadow(
                          color: colors.charcoal.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSearchResultsFeed(List<MemoryEntry> results, VoiceInputState voiceState) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 1.5));
    }
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              'Keine Einträge gefunden',
              style: AppTypography.textTheme(context).bodyMedium?.copyWith(color: AppColors.of(context).mutedText),
            ),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
            child: Text(
              '${results.length} Ergebnis${results.length != 1 ? "se" : ""} gefunden',
              style: AppTypography.textTheme(context).bodySmall?.copyWith(color: AppColors.of(context).mutedText),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
            (context, i) {
              final e = results[i];
              if (e.id == null) return const SizedBox.shrink();
              return JournalEntryWidget(
                entry: e,
                onCheckboxChanged: e.type == EntryType.actionable
                    ? (val) async {
                        await MemoryRepository().toggleCompletion(e.id!, val ?? false);
                        ref.invalidate(memoryEntriesProvider);
                      }
                    : null,
                onDelete: () async {
                  await ref.read(memoryRepoProvider).delete(e.id!);
                  setState(() => _searchResults = _searchResults?.where((r) => r.id != e.id).toList());
                },
              );
            },
              childCount: results.length,
            ),
          ),
        ),
      ],
    );
  }

  void _toggleSearch() {

    HapticFeedback.selectionClick();
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchController.clear();
        _searchResults = null;
      } else {
        // Auto-focus the search field
        WidgetsBinding.instance.addPostFrameCallback((_) => _searchFocus.requestFocus());
      }
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = null);
      return;
    }
    setState(() => _isSearching = true);
    final results = await MemoryRepository().searchEntries(query);
    if (mounted) setState(() { _searchResults = results; _isSearching = false; });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: GlassPill(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.search, size: 20, color: AppColors.of(context).charcoal.withValues(alpha: 0.7)),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                style: AppTypography.textTheme(context).bodyLarge?.copyWith(
                  color: AppColors.of(context).charcoal,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Nach Gedanken suchen...',
                  hintStyle: AppTypography.textTheme(context).bodyLarge?.copyWith(
                    color: AppColors.of(context).mutedText.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: _runSearch,
              ),
            ),
            // Close / Clear Search
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  _runSearch('');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.cancel_rounded, size: 18, color: AppColors.of(context).mutedText.withValues(alpha: 0.4)),
                ),
              ),
            const SizedBox(width: 4),
            // Cancel button
            GestureDetector(
              onTap: _toggleSearch,
              child: Text(
                'Abbrechen',
                style: TextStyle(
                  color: AppColors.of(context).bioAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
// ===== Header Widget =====

class _CanvasHeader extends ConsumerWidget {
  final String today;
  final bool isSearchActive;
  final VoidCallback? onSearchTap;
  const _CanvasHeader({required this.today, this.isSearchActive = false, this.onSearchTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/settings');
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              child: const GlassPill(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.settings_rounded, size: 20, color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const Spacer(),
          GlassPill(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Text(today, style: AppTypography.textTheme(context).labelLarge),
          ),
          const Spacer(),
          Row(
            children: [
              // Search button
              if (!isSearchActive)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSearchTap?.call();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: const GlassPill(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.search, size: 20, color: Color(0xFF1E293B)),
                    ),
                  ),
                ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/people');
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const GlassPill(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.people_outline, size: 20, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  showSecondBrainPopup(context);
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: const GlassPill(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.psychology, size: 20, color: Color(0xFF0D9488)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ===== Live Transcript Preview Row =====

class _LiveTranscriptRow extends StatelessWidget {
  final String text;
  final bool isProcessing;
  const _LiveTranscriptRow({required this.text, this.isProcessing = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: AppTypography.handwritten(context).copyWith(
                  color: AppColors.of(context).charcoal.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: _DotsIndicator(),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (isProcessing)
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.of(context).bioAccent,
            ),
          )
        else
          PulseDot(color: AppColors.of(context).bioAccent, size: 8),
      ],
    );
  }
}

// ===== Animated Dots Indicator (Apple-style typing dots) =====

class _DotsIndicator extends StatefulWidget {
  const _DotsIndicator();

  @override
  State<_DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<_DotsIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _anims = _ctrls
        .map((c) => Tween<double>(begin: 0.25, end: 1.0).animate(
              CurvedAnimation(parent: c, curve: Curves.easeInOut),
            ))
        .toList();

    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 180), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder: (_, __) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Opacity(
              opacity: _anims[i].value,
              child: Transform.translate(
                offset: Offset(0, -4 * _anims[i].value + 2),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.of(context).bioAccent,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
