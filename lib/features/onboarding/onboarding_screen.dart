import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _buttonScaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _buttonScaleAnim;

  static const Color primaryPurple = Color(0xFF624bba);
  static const Color slate900 = Color(0xFF0f172a);
  static const Color slate400 = Color(0xFF94a3b8);
  static const Color slate200 = Color(0xFFe2e8f0);
  static const Color slate50 = Color(0xFFf8fafc);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _buttonScaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonScaleCtrl, curve: Curves.easeOut),
    );
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _buttonScaleCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _fadeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildPaperTexture(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                      _buildStep4(),
                    ],
                  ),
                ),
                _buildProgressIndicator(),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaperTexture() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.02,
        child: CustomPaint(
          painter: _NoisePainter(),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bubble_chart_outlined,
            color: primaryPurple.withValues(alpha: 0.6),
            size: 28,
          ),
          const SizedBox(width: 8),
          Text(
            'Remi',
            style: GoogleFonts.newsreader(
              fontSize: 24,
              fontStyle: FontStyle.italic,
              color: primaryPurple.withValues(alpha: 0.8),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24 : 6,
            height: 4,
            decoration: BoxDecoration(
              color: isActive ? slate900 : slate200,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return _OnboardingPage(
      title: 'Your head,',
      italicText: 'finally free.',
      subtitle:
          'Remi captures your fleeting ideas, tasks, and memories before they are lost.',
      child: _buildIntroVisual(),
    );
  }

  Widget _buildStep2() {
    return _OnboardingPage(
      title: 'Speak as',
      italicText: 'you are.',
      subtitle:
          'We\'ll take care of the rest. This is Intelligence.',
      child: _buildVoiceVisual(),
    );
  }

  Widget _buildStep3() {
    return _OnboardingPage(
      title: 'Time for your',
      italicText: 'first thought.',
      subtitle:
          'So Remi can hear and heal your "messy" thoughts, we need access to your microphone.',
      child: _buildMicVisual(),
    );
  }

  Widget _buildStep4() {
    return _OnboardingPage(
      title: 'Gentle',
      italicText: 'Reminders.',
      subtitle:
          'Get alerts for your curated tasks so you can keep your head clear for the essentials.',
      child: _buildNotificationVisual(),
    );
  }

  Widget _buildIntroVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 256,
          height: 256,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: slate50,
          ),
        ),
        Positioned(
          top: 0,
          right: 48,
          child: _FloatingIcon(
            icon: Icons.sticky_note_2_outlined,
            rotation: 0.1,
          ),
        ),
        Positioned(
          top: 80,
          left: 16,
          child: _FloatingIcon(
            icon: Icons.event_outlined,
            rotation: -0.2,
          ),
        ),
        Positioned(
          bottom: 48,
          right: 16,
          child: _FloatingIcon(
            icon: Icons.psychology_outlined,
            rotation: 0.05,
          ),
        ),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(color: slate200.withValues(alpha: 0.5)),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 40,
            color: primaryPurple.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 288,
          height: 288,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: slate50,
          ),
        ),
        Container(
          width: 256,
          height: 256,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: slate200.withValues(alpha: 0.5)),
          ),
        ),
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: slate50),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Transform.rotate(
            angle: 0.1,
            child: Text(
              '"Capturing the essence..."',
              style: GoogleFonts.newsreader(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: slate400,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          child: Transform.rotate(
            angle: -0.05,
            child: Text(
              '"...thought into form."',
              style: GoogleFonts.newsreader(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: slate400,
              ),
            ),
          ),
        ),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 32,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(color: slate50),
          ),
          child: Icon(
            Icons.mic,
            size: 48,
            color: slate400,
          ),
        ),
      ],
    );
  }

  Widget _buildMicVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 256,
          height: 256,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: slate50,
          ),
        ),
        Positioned(
          top: 0,
          right: 16,
          child: _ProcessingCard(),
        ),
        Container(
          width: 128,
          height: 128,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 48,
                spreadRadius: 0,
              ),
            ],
            border: Border.all(color: slate50),
          ),
          child: Icon(
            Icons.mic,
            size: 40,
            color: slate900,
          ),
        ),
        Positioned(
          bottom: 48,
          left: 16,
          child: _AwaitingAccessBadge(),
        ),
      ],
    );
  }

  Widget _buildNotificationVisual() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 192,
          height: 192,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: slate50,
          ),
        ),
        Icon(
          Icons.notifications_outlined,
          size: 72,
          color: const Color(0xFFcbd5e1),
        ),
        Positioned(
          bottom: 0,
          child: _TaskSuggestionCard(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final isLast = _currentPage == 3;

    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: slate50),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (isLast) {
                ref.read(onboardingProvider.notifier).completeOnboarding();
                context.go('/');
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Text(
              'Skip',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: slate400,
              ),
            ),
          ),
          GestureDetector(
            onTapDown: (_) => _buttonScaleCtrl.forward(),
            onTapUp: (_) {
              _buttonScaleCtrl.reverse();
              _handleNext(isLast);
            },
            onTapCancel: () => _buttonScaleCtrl.reverse(),
            child: AnimatedBuilder(
              animation: _buttonScaleAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnim.value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                decoration: BoxDecoration(
                  color: slate900,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      isLast ? 'Get Started' : 'Next',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNext(bool isLast) async {
    HapticFeedback.mediumImpact();

    if (_currentPage == 2) {
      final micStatus = await Permission.microphone.request();
      if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone access is needed for voice notes'),
            ),
          );
        }
        return;
      }
    } else if (_currentPage == 3) {
      final notifStatus = await Permission.notification.request();
      if (notifStatus.isDenied || notifStatus.isPermanentlyDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications are needed for reminders'),
            ),
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String italicText;
  final String subtitle;
  final Widget child;

  const _OnboardingPage({
    required this.title,
    required this.italicText,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          child,
          const SizedBox(height: 48),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: GoogleFonts.newsreader(
                    fontSize: 40,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1b1c19),
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: '\n',
                ),
                TextSpan(
                  text: italicText,
                  style: GoogleFonts.newsreader(
                    fontSize: 40,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1b1c19),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: const Color(0xFF484550),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIcon extends StatelessWidget {
  final IconData icon;
  final double rotation;

  const _FloatingIcon({
    required this.icon,
    this.rotation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFf1f5f9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: _OnboardingScreenState.slate400,
        ),
      ),
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.05,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: const Color(0xFFf1f5f9)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFe2e8f0),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'PROCESSING...',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: const Color(0xFF94a3b8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meeting notes',
                    style: GoogleFonts.newsreader(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Color(0xFF94a3b8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFf1f5f9),
                borderRadius: BorderRadius.circular(2),
              ),
              child: const FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.75,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF0f172a),
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AwaitingAccessBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: const Color(0xFFf1f5f9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.settings_voice_outlined,
              size: 14,
              color: Color(0xFF94a3b8),
            ),
            const SizedBox(width: 8),
            Text(
              'Awaiting Access',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskSuggestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(color: const Color(0xFFf1f5f9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFf8fafc),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 18,
              color: Color(0xFF94a3b8),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buy lilies',
                style: GoogleFonts.newsreader(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1b1c19),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'REMI SUGGESTION',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: const Color(0xFF94a3b8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = DateTime.now().microsecondsSinceEpoch;
    final paint = Paint()..color = Colors.black;
    
    for (int i = 0; i < 5000; i++) {
      final x = (random * (i + 1) * 17) % size.width.toInt();
      final y = (random * (i + 1) * 23) % size.height.toInt();
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
