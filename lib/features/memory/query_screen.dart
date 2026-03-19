import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/repositories/repositories.dart';
import '../../core/providers/app_providers.dart';

class QueryScreen extends ConsumerStatefulWidget {
  const QueryScreen({super.key});

  @override
  ConsumerState<QueryScreen> createState() => _QueryScreenState();
}

class _QueryScreenState extends ConsumerState<QueryScreen> {
  final _ctrl = TextEditingController();
  String? _answer;
  bool _loading = false;

  Future<void> _ask(String question) async {
    if (question.trim().isEmpty) return;
    setState(() { _loading = true; _answer = null; });

    final gemini = ref.read(geminiServiceProvider);
    final repo = MemoryRepository();
    final entries = await repo.getRecentEntries(limit: 30);
    final memories = entries.map((e) => e.summary.isNotEmpty ? e.summary : e.rawText).toList();

    final answer = await gemini.querySecondBrain(
      question: question,
      recentMemories: memories,
    );
    setState(() { _answer = answer; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).paper,
      appBar: AppBar(
        title: const Text('Ask your Second Brain'),
        backgroundColor: AppColors.of(context).paper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Query field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: _ask,
                    decoration: InputDecoration(
                      hintText: 'What did I say about the weekend?',
                      prefixIcon: Icon(Icons.auto_awesome, color: AppColors.of(context).bioAccent, size: 20),
                    ),
                    style: AppTypography.textTheme(context).bodyLarge,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _ask(_ctrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.of(context).charcoal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Answer area
            if (_loading)
              Column(
                children: [
                  CircularProgressIndicator(color: AppColors.of(context).bioAccent, strokeWidth: 1.5),
                  const SizedBox(height: 12),
                  Text('Asking your Second Brain…',
                      style: AppTypography.textTheme(context).bodyMedium),
                ],
              ),
            if (_answer != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.of(context).bioAccent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.of(context).bioAccent.withValues(alpha: 0.2)),
                ),
                child: Text(_answer!, style: AppTypography.textTheme(context).bodyLarge),
              ),

            if (_answer == null && !_loading) ...[
              const SizedBox(height: 40),
              Icon(Icons.auto_awesome_outlined, size: 48, color: AppColors.of(context).mutedText.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Ask anything about your memories,\ntasks, or the people you\'ve mentioned.',
                textAlign: TextAlign.center,
                style: AppTypography.textTheme(context).bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
