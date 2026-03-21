import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/env/app_env.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/theme_provider.dart';
import '../../data/services/supabase_service.dart';
import '../../core/widgets/core_widgets.dart';

// Moved incognitoProvider to app_providers.dart

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyCtrl = TextEditingController();
  final _supabaseUrlCtrl = TextEditingController();
  final _supabaseAnonKeyCtrl = TextEditingController();
  bool _obscureKey = true;
  bool _obscureSupaKey = true;
  String? _savedKeyPreview;
  bool _keySaved = false;
  bool _supabaseSaved = false;
  String? _savedSupaUrlPreview;

  @override
  void initState() {
    super.initState();
    _loadKey();
    _loadSupabase();
  }

  Future<void> _loadKey() async {
    final key = await AppEnv.getGeminiApiKey();
    if (key != null && key.isNotEmpty) {
      setState(() {
        _savedKeyPreview = '${key.substring(0, 8)}••••••••';
        _keySaved = true;
      });
      // Re-initialize Gemini service
      ref.read(geminiServiceProvider).initialize(key);
    }
  }

  Future<void> _loadSupabase() async {
    final url = await AppEnv.getSupabaseUrl();
    final key = await AppEnv.getSupabaseAnonKey();
    if (url != null && url.isNotEmpty && key != null && key.isNotEmpty) {
      setState(() {
        _supabaseSaved = true;
        _savedSupaUrlPreview =
            url.length > 20 ? '${url.substring(0, 20)}...' : url;
      });
      // Initialize Supabase if not already
      await SupabaseService().initialize(url: url, anonKey: key);
    }
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyCtrl.text.trim();
    if (key.isEmpty) return;
    await AppEnv.setGeminiApiKey(key);
    ref.read(geminiServiceProvider).initialize(key);
    setState(() {
      _savedKeyPreview = '${key.substring(0, 8)}••••••••';
      _keySaved = true;
      _apiKeyCtrl.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Groq API key saved ✓')),
      );
    }
  }

  Future<void> _clearApiKey() async {
    await AppEnv.clearGeminiApiKey();
    setState(() {
      _keySaved = false;
      _savedKeyPreview = null;
    });
  }

  Future<void> _saveSupabase() async {
    final url = _supabaseUrlCtrl.text.trim();
    final key = _supabaseAnonKeyCtrl.text.trim();
    if (url.isEmpty || key.isEmpty) return;

    try {
      await AppEnv.setSupabaseUrl(url);
      await AppEnv.setSupabaseAnonKey(key);
      await SupabaseService().initialize(url: url, anonKey: key);

      setState(() {
        _supabaseSaved = true;
        _savedSupaUrlPreview =
            url.length > 20 ? '${url.substring(0, 20)}...' : url;
        _supabaseUrlCtrl.clear();
        _supabaseAnonKeyCtrl.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supabase configuration saved ✓')),
        );
      }
    } catch (e) {
      await AppEnv.setSupabaseUrl('');
      await AppEnv.setSupabaseAnonKey('');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save Supabase config: $e')),
        );
      }
    }
  }

  Future<void> _clearSupabase() async {
    await AppEnv.setSupabaseUrl('');
    await AppEnv.setSupabaseAnonKey('');
    setState(() {
      _supabaseSaved = false;
      _savedSupaUrlPreview = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIncognito = ref.watch(incognitoProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).paper,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).paper,
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            HapticFeedback.selectionClick();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Appearance Section ────────────────────────────────────
            const _SectionHeader('Appearance'),
            const SizedBox(height: 12),
            _SettingsRow(
              icon: Icons.brightness_6_rounded,
              iconColor: AppColors.of(context).charcoal,
              title: 'App Theme',
              subtitle: 'Select light, dark, or system default',
              action: DropdownButton<ThemeMode>(
                value: themeMode,
                underline: const SizedBox(),
                dropdownColor: AppColors.of(context).cardSurface,
                style: TextStyle(
                    color: AppColors.of(context).charcoal,
                    fontWeight: FontWeight.w500),
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('Light')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                ],
                onChanged: (mode) {
                  if (mode != null) {
                    HapticFeedback.selectionClick();
                    ref.read(themeModeProvider.notifier).setTheme(mode);
                  }
                },
              ),
            ),
            const SizedBox(height: 32),

            // ── AI Brain API Key Section ─────────────────────────────
            const _SectionHeader('AI Brain (Groq)'),
            const SizedBox(height: 12),
            if (_keySaved)
              _SettingsRow(
                icon: Icons.key_rounded,
                title: 'Groq API Key',
                subtitle: _savedKeyPreview ?? 'Saved',
                action: TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _clearApiKey();
                  },
                  child: const Text('Remove',
                      style: TextStyle(color: AppColors.errorRed)),
                ),
              )
            else ...[
              Text('Add your Groq API key (Llama 3) to enable AI extraction.',
                  style: AppTypography.textTheme(context).bodyMedium),
              const SizedBox(height: 10),
              TextField(
                controller: _apiKeyCtrl,
                obscureText: _obscureKey,
                decoration: InputDecoration(
                  hintText: 'gsk_...',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureKey
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscureKey = !_obscureKey);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _saveApiKey();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.of(context).charcoal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save API Key'),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Cloud Backup (Supabase) Section ───────────────────────
            const _SectionHeader('Cloud Backup (Supabase)'),
            const SizedBox(height: 12),
            if (_supabaseSaved)
              _SettingsRow(
                icon: Icons.cloud_done_rounded,
                iconColor: AppColors.of(context).bioAccent,
                title: 'Supabase Connected',
                subtitle: _savedSupaUrlPreview ?? 'Active',
                action: TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _clearSupabase();
                  },
                  child: const Text('Disconnect',
                      style: TextStyle(color: AppColors.errorRed)),
                ),
              )
            else ...[
              Text(
                  'Connect to Supabase to backup your memories across devices.',
                  style: AppTypography.textTheme(context).bodyMedium),
              const SizedBox(height: 10),
              TextField(
                controller: _supabaseUrlCtrl,
                decoration: const InputDecoration(
                  hintText: 'https://xyz.supabase.co',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                style: AppTypography.textTheme(context).bodyMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _supabaseAnonKeyCtrl,
                obscureText: _obscureSupaKey,
                decoration: InputDecoration(
                  hintText: 'Anon Key',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureSupaKey
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _obscureSupaKey = !_obscureSupaKey);
                    },
                  ),
                ),
                style: AppTypography.textTheme(context).bodyMedium,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _saveSupabase();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.of(context).bioAccent.withValues(alpha: 0.12),
                    foregroundColor: AppColors.of(context).bioAccent,
                    elevation: 0,
                    side: BorderSide(
                        color:
                            AppColors.of(context).bioAccent.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Connect to Cloud'),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // ── Privacy Section ────────────────────────────────────
            const _SectionHeader('Privacy'),
            const SizedBox(height: 12),
            _SettingsRow(
              icon: isIncognito
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              iconColor: isIncognito
                  ? AppColors.of(context).bioPulse
                  : AppColors.of(context).charcoal,
              title: 'Incognito Mode',
              subtitle: isIncognito
                  ? 'AI is not listening or saving'
                  : 'AI is active — tap to pause',
              action: Switch(
                value: isIncognito,
                thumbColor: WidgetStateProperty.all(AppColors.of(context).bioAccent),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  ref.read(incognitoProvider.notifier).state = val;
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── About ──────────────────────────────────────────────
            const _SectionHeader('About'),
            const SizedBox(height: 12),
            const _SettingsRow(
              icon: Icons.info_outline_rounded,
              title: 'Remi',
              subtitle: 'Ambient Memory v1.0.0',
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.textTheme(context).labelMedium?.copyWith(
            letterSpacing: 1.5,
            color: AppColors.of(context).bioAccent,
          ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? action;

  const _SettingsRow({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPill(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          Icon(icon,
              size: 22, color: iconColor ?? AppColors.of(context).charcoal),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.textTheme(context).titleMedium),
                Text(subtitle,
                    style: AppTypography.textTheme(context).bodySmall),
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
