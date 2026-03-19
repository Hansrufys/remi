import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: colors.paper,
      body: Stack(
        children: [
          // Bioluminescent Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: _BioluminescentGlow(color: colors.bioAccent.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _BioluminescentGlow(color: colors.bioMint.withValues(alpha: 0.1)),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildStep(
                        title: 'Dein Kopf,',
                        handwrittenAccent: 'endlich frei.',
                        subtitle: 'Remi fängt deine flüchtigen Ideen, Aufgaben und Erinnerungen auf, bevor sie verloren gehen.',
                        content: _buildIntroVisual(colors),
                      ),
                      _buildStep(
                        title: 'Sprich, wie dir der',
                        handwrittenAccent: 'Schnabel gewachsen ist.',
                        subtitle: 'Wir reparieren den Rest. Das ist Speech Healing.',
                        content: _buildSpeechHealingDemo(colors),
                      ),
                      _buildStep(
                        title: 'Zeit für den',
                        handwrittenAccent: 'ersten Gedanken.',
                        subtitle: 'Damit Remi deine "unordentlichen" Gedanken hören und heilen kann, benötigen wir Zugriff auf dein Mikrofon. Deine Privatsphäre ist uns wichtig.',
                        content: _buildPermissionVisual(colors, Icons.mic_rounded),
                      ),
                      _buildStep(
                        title: 'Sanfte',
                        handwrittenAccent: 'Erinnerungen.',
                        subtitle: 'Erhalte Hinweise zu deinen geheilten Aufgaben, damit du den Kopf für das Wesentliche frei hast.',
                        content: _buildPermissionVisual(colors, Icons.notifications_active_rounded),
                      ),
                    ],
                  ),
                ),
                _buildFooter(colors),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String title,
    required String handwrittenAccent,
    required String subtitle,
    required Widget content,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          content,
          const SizedBox(height: 48),
          
          // Title with Handwritten Accent
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.of(context).charcoal,
                  height: 1.1,
                ),
              ),
              Transform.rotate(
                angle: -0.05,
                child: Text(
                  handwrittenAccent,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nanumPenScript(
                    fontSize: 40,
                    color: AppColors.of(context).bioAccent,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.of(context).mutedText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroVisual(AppColorsExtension colors) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.bioAccent.withValues(alpha: 0.1),
            colors.bioMint.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome,
          size: 80,
          color: colors.bioAccent.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSpeechHealingDemo(AppColorsExtension colors) {
    return Container(
      height: 280,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Messy Input
          _buildDemoBubble(
            text: '„Äh, ich muss... äh... Saskia sagen, dass... wegen der Dubai Schokolade am Dienstag...“',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: colors.mutedText,
            ),
            color: colors.mutedText.withValues(alpha: 0.05),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ),
          // Clean Output
          _buildDemoBubble(
            text: 'Aufgabe: Saskia wegen der Dubai Schokolade am Dienstag kontaktieren.',
            style: GoogleFonts.sourceSerif4(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.charcoal,
            ),
            color: colors.bioMint.withValues(alpha: 0.2),
            isMagic: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoBubble({
    required String text,
    required TextStyle style,
    required Color color,
    bool isMagic = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: isMagic ? Border.all(color: AppColors.light.bioMint.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        text,
        style: style,
      ),
    );
  }

  Widget _buildPermissionVisual(AppColorsExtension colors, IconData icon) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.bioAccent.withValues(alpha: 0.1),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 100,
          color: colors.bioAccent,
        ),
      ),
    );
  }

  Widget _buildFooter(AppColorsExtension colors) {
    final isLast = _currentPage == 3;
    
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final active = _currentPage == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: active ? colors.bioAccent : colors.mutedText.withValues(alpha: 0.2),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          
          // Primary Button
          GestureDetector(
        onTap: () async {
          HapticFeedback.mediumImpact();

          if (_currentPage == 2) {
            final micStatus = await Permission.microphone.request();
            if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mikrofon-Zugriff wird für Sprachnotizen benötigt')),
                );
              }
              return;
            }
          } else if (_currentPage == 3) {
            final notifStatus = await Permission.notification.request();
            if (notifStatus.isDenied || notifStatus.isPermanentlyDenied) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Benachrichtigungen werden für Erinnerungen benötigt')),
                );
              }
              return;
            }
          }

              if (isLast) {
                if (mounted) {
                  ref.read(onboardingProvider.notifier).completeOnboarding();
                  context.go('/');
                }
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOutCubic,
                );
              }
            },
            child: Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                color: colors.charcoal,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.charcoal.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isLast ? 'Loslegen' : 'Weiter',
                  style: GoogleFonts.inter(
                    color: colors.paper,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioluminescentGlow extends StatelessWidget {
  final Color color;
  const _BioluminescentGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}
