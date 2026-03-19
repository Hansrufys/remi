import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/env/app_env.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/theme_provider.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_worker.dart';
import 'features/echoes/echo_scheduler_service.dart';
import 'data/services/quick_entry_service.dart';
import 'data/services/supabase_service.dart';
import 'data/repositories/repositories.dart';
import 'data/models/memory_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await registerBackgroundOrganizer();

  runApp(
    const ProviderScope(
      child: RemiApp(),
    ),
  );
}

class RemiApp extends ConsumerStatefulWidget {
  const RemiApp({super.key});

  @override
  ConsumerState<RemiApp> createState() => _RemiAppState();
}

class _RemiAppState extends ConsumerState<RemiApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeGemini();
    _initializeSupabase();
    _initializeEchoes();
    _setupQuickEntry();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Force AppColors to sync with the new system brightness
    ref.read(themeModeProvider.notifier).updateAppColorsSync(context);
    setState(() {}); // Trigger a rebuild so widgets read the new AppColors
  }

  void _setupQuickEntry() {
    final quickEntry = ref.read(quickEntryProvider);
    
    // Set up listener for widget clicks
    quickEntry.setupWidgetLinkListener((uri) {
      if (uri != null) {
        debugPrint('Widget link received: $uri');
        if (uri.scheme == 'remi' && uri.host == 'quick-record') {
          // Navigate to canvas with quick record enabled
          AppRouter.router.push('/?quick=true');
        }
      }
    });
    
    // Update widget with current data on app start
    _updateWidgetOnStart();
  }
  
  Future<void> _updateWidgetOnStart() async {
    try {
      final repo = MemoryRepository();
      final entries = await repo.getRecentEntries(limit: 10);
      
      final taskCount = entries.where((e) => e.type == EntryType.actionable && !e.isCompleted).length;
      final memoryCount = entries.where((e) => e.type == EntryType.insight).length;
      final latestMemory = entries.isNotEmpty ? entries.first.summary : null;
      
      ref.read(quickEntryProvider).updateWidgetData(
        tasks: taskCount,
        memories: memoryCount,
        latestMemory: latestMemory,
      );
    } catch (e) {
      debugPrint('Widget init error: $e');
    }
  }

  Future<void> _initializeEchoes() async {
    final scheduler = ref.read(echoSchedulerProvider);
    await scheduler.scheduleStandardEchoes();
    await scheduler.detectForgottenThoughts();
  }

  Future<void> _initializeGemini() async {
    final key = await AppEnv.getGeminiApiKey();
    if (key != null && key.isNotEmpty) {
      ref.read(geminiServiceProvider).initialize(key);
    }
  }

  Future<void> _initializeSupabase() async {
    final url = await AppEnv.getSupabaseUrl();
    final anonKey = await AppEnv.getSupabaseAnonKey();
    
    if (url != null && anonKey != null) {
      await SupabaseService().initialize(url: url, anonKey: anonKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Remi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(context),
      darkTheme: AppTheme.dark(context),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
