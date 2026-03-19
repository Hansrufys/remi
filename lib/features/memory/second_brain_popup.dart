import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';
import '../../data/repositories/repositories.dart';
import '../voice/voice_input_notifier.dart';


Future<void> showSecondBrainPopup(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _SecondBrainPopup(),
    ),
  );
}

class _SecondBrainPopup extends ConsumerStatefulWidget {
  const _SecondBrainPopup();

  @override
  ConsumerState<_SecondBrainPopup> createState() => _SecondBrainPopupState();
}

class _SecondBrainPopupState extends ConsumerState<_SecondBrainPopup> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final List<Map<String, String>> _chatHistory = [];
  bool _loading = false;
  bool _isListening = false;
  String _transcript = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  Future<void> _toggleVoice() async {
    HapticFeedback.selectionClick();
    final voiceNotifier = ref.read(voiceInputProvider.notifier);
    final voiceState = ref.read(voiceInputProvider);

    if (voiceState.status == VoiceState.listening) {
      final text = await voiceNotifier.stopListening();
      if (text != null && text.isNotEmpty) {
        setState(() {
          _isListening = false;
          _transcript = '';
          _ctrl.text = text;
        });
        _ask(text);
      }
    } else {
      await voiceNotifier.startListening();
      setState(() {
        _isListening = true;
        _transcript = '';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listen<VoiceInputState>(voiceInputProvider, (previous, next) {
      if (next.status == VoiceState.listening) {
        setState(() {
          _isListening = true;
          _transcript = next.transcript;
        });
      } else if (next.status == VoiceState.idle && _isListening) {
        if (next.transcript.isNotEmpty) {
          setState(() {
            _ctrl.text = next.transcript;
            _isListening = false;
          });
          _ask(next.transcript);
          ref.read(voiceInputProvider.notifier).resetState();
        } else {
          setState(() => _isListening = false);
        }
      }
    });
  }

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _chatHistory.add({'role': 'user', 'content': question});
      _ctrl.clear();
    });

    _scrollToBottom();

    final gemini = ref.read(geminiServiceProvider);

    try {
      final repo = MemoryRepository();
      final personRepo = PersonProfileRepository();
      
      final entries = await repo.getRecentEntries(limit: 40);
      final memories = entries.map((e) => e.summary.isNotEmpty ? e.summary : e.rawText).toList();
      
      // Fetch Person Insights
      final people = await personRepo.getAll();
      for (final p in people) {
        if (p.insightNotes.isNotEmpty) {
          final summary = p.insightNotes.join(". ");
          memories.add("Über ${p.name}: $summary");
        }
      }

      final answer = await gemini
          .querySecondBrain(
            question: question,
            recentMemories: memories,
            chatHistory: List.from(_chatHistory.where((m) => m['content'] != question)),
          )
          .timeout(
            const Duration(seconds: 20),
            onTimeout: () => 'Das Gehirn braucht gerade länger als üblich. Netz ok?',
          );

      if (mounted) {
        setState(() {
          _chatHistory.add({'role': 'assistant', 'content': answer});
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _chatHistory.add({'role': 'assistant', 'content': 'Keine Antwort gefunden. Versuche es nochmal.'});
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: AppColors.of(context).paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(context),
          const SizedBox(height: 16),
          _buildHeader(context),
          const SizedBox(height: 12),
          
          // Conversation View
          Flexible(
            child: _chatHistory.isEmpty
                ? _buildEmptyState(context)
                : _buildChatList(),
          ),

          const SizedBox(height: 12),
          if (_isListening && _transcript.isNotEmpty) _buildTranscriptRow(),
          const SizedBox(height: 8),
          _buildInputRow(context),
        ],
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.of(context).charcoal.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.psychology, size: 28, color: AppColors.of(context).bioAccent),
        const SizedBox(width: 8),
        Text(
          'Zweites Gehirn',
          style: AppTypography.textTheme(context).titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const SizedBox(height: 40),
        Text(
          'Stell mir eine Frage zu deinen Gedanken.',
          style: AppTypography.textTheme(context).bodyMedium?.copyWith(
            color: AppColors.of(context).mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _chatHistory.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _chatHistory.length) {
          return _buildLoadingBubble(context);
        }
        final msg = _chatHistory[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(context, msg['content'] ?? '', isUser);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser 
              ? AppColors.of(context).bioAccent.withValues(alpha: 0.12)
              : AppColors.of(context).cardSurface,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(4) : null,
            bottomLeft: !isUser ? const Radius.circular(4) : null,
          ),
          border: Border.all(
            color: isUser 
              ? AppColors.of(context).bioAccent.withValues(alpha: 0.3)
              : AppColors.of(context).borderLight,
          ),
        ),
        child: Text(
          text,
          style: AppTypography.textTheme(context).bodyMedium?.copyWith(
            color: AppColors.of(context).charcoal.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingBubble(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.of(context).cardSurface,
          borderRadius: BorderRadius.circular(16).copyWith(bottomLeft: const Radius.circular(4)),
        ),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.of(context).bioAccent),
        ),
      ),
    );
  }

  Widget _buildTranscriptRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        _transcript,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.textTheme(context).bodySmall?.copyWith(
          color: AppColors.of(context).bioAccent.withValues(alpha: 0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildInputRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            onSubmitted: _ask,
            decoration: InputDecoration(
              hintText: _isListening ? 'Höre zu...' : 'Frag mich was...',
              hintStyle: TextStyle(color: AppColors.of(context).charcoal.withValues(alpha: 0.4)),
              filled: true,
              fillColor: AppColors.of(context).cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            style: AppTypography.textTheme(context).bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        _buildVoiceToggleButton(context),
        const SizedBox(width: 8),
        _buildSendButton(context),
      ],
    );
  }

  Widget _buildVoiceToggleButton(BuildContext context) {
    return GestureDetector(
      onTap: _toggleVoice,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isListening ? AppColors.of(context).bioPulse : AppColors.of(context).cardSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: _isListening ? Colors.white : AppColors.of(context).charcoal,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSendButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _ask(_ctrl.text),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.of(context).charcoal,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
