import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/memory_entry.dart';
import '../../data/models/person_profile.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/gemini_service.dart';

/// Singleton GeminiService provider, available app-wide.
final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());

/// Global state for fog/incognito mode.
final incognitoProvider = StateProvider<bool>((ref) => false);

/// List of memory entries for the daily feed (today's + pending tasks), sorted by AI priority.
final memoryEntriesProvider = FutureProvider<List<MemoryEntry>>((ref) async {
  return MemoryRepository().getDailyFeedEntriesSorted();
});

/// List of all person profiles.
final allPeopleProvider = FutureProvider<List<PersonProfile>>((ref) async {
  return PersonProfileRepository().getAll();
});

/// Repository providers for direct access if needed
final memoryRepoProvider = Provider((_) => MemoryRepository());
final personRepoProvider = Provider((_) => PersonProfileRepository());
