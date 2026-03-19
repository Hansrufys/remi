import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/core_widgets.dart';
import '../../core/providers/app_providers.dart';
import '../../data/models/person_profile.dart';

class PeopleScreen extends ConsumerWidget {
  const PeopleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(allPeopleProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).paper,
      appBar: AppBar(
        title: const Text('Soul Profiles'),
        backgroundColor: AppColors.of(context).paper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
      ),
      body: people.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.of(context).bioAccent)),
        error: (e, _) =>
            Center(child: Text('Error loading profiles', style: TextStyle(color: AppColors.of(context).mutedText))),
        data: (list) {
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.1,
            ),
            itemCount: list.length,
            itemBuilder: (context, i) => _ProfileCard(profile: list[i]),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final PersonProfile profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final lastNote = profile.insightNotes.isNotEmpty
        ? profile.insightNotes.last
        : 'No memories yet';

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/people/${profile.id}');
      },
      child: GlassPill(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            AvatarInitial(
              label: profile.avatarInitial ?? profile.name, 
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(profile.name, style: AppTypography.textTheme(context).titleMedium),
            const SizedBox(height: 4),
            Text(
              lastNote,
              style: AppTypography.textTheme(context).bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '${profile.insightNotes.length} memories',
              style: AppTypography.marginMeta(context).copyWith(color: AppColors.of(context).bioAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Text(
            'Keine Soul-Profile vorhanden',
            style: AppTypography.textTheme(context).headlineSmall?.copyWith(
              color: AppColors.of(context).charcoal,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Erwähne jemanden in einem Gedanken und Remi wird sich an ihn erinnern.',
              textAlign: TextAlign.center,
              style: AppTypography.textTheme(context).bodyMedium?.copyWith(
                color: AppColors.of(context).mutedText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
