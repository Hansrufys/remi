import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/voice/voice_input_notifier.dart';

/// The morphing blob voice/action button — primary CTA at bottom of canvas.
class PulseButton extends StatefulWidget {
  final VoiceState voiceState;
  final VoidCallback onTap;

  const PulseButton({
    super.key,
    required this.voiceState,
    required this.onTap,
  });

  @override
  State<PulseButton> createState() => _PulseButtonState();
}

class _PulseButtonState extends State<PulseButton>
    with TickerProviderStateMixin {
  late AnimationController _morphCtrl;
  late AnimationController _ringCtrl;
  late AnimationController _activeCtrl;
  late Animation<double> _morphAnim;
  late Animation<double> _ringAnim;
  late Animation<double> _activeAnim;

  @override
  void initState() {
    super.initState();

    _morphCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _morphAnim = CurvedAnimation(parent: _morphCtrl, curve: Curves.easeInOut);
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut);
    _activeAnim = CurvedAnimation(parent: _activeCtrl, curve: Curves.elasticOut);
  }

  @override
  void didUpdateWidget(PulseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceState == VoiceState.listening) {
      _activeCtrl.forward();
    } else {
      _activeCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _morphCtrl.dispose();
    _ringCtrl.dispose();
    _activeCtrl.dispose();
    super.dispose();
  }

  BorderRadius _morphBorderRadius(double t) {
    // Replicates the CSS fluid-morph keyframes
    final r1 = 40 + t * 20;
    final r2 = 60 - t * 20;
    final r3 = 70 - t * 40;
    final r4 = 30 + t * 40;
    return BorderRadius.only(
      topLeft: Radius.circular(r1),
      topRight: Radius.circular(r2),
      bottomLeft: Radius.circular(r3),
      bottomRight: Radius.circular(r4),
    );
  }

  Color get _buttonColor {
    if (widget.voiceState == VoiceState.listening) return AppColors.of(context).bioAccent;
    return AppColors.of(context).charcoal;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_morphAnim, _ringAnim, _activeAnim]),
      builder: (context, _) {
        final isListening = widget.voiceState == VoiceState.listening;

        return GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ink-spread glow ring
              if (isListening)
                Transform.scale(
                  scale: 1.0 + _ringAnim.value * 0.8,
                  child: Opacity(
                    opacity: (1 - _ringAnim.value) * 0.4,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.of(context).bioAccent,
                      ),
                    ),
                  ),
                ),

              // White outer ring (always visible)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.of(context).paper,
                  border: Border.all(
                    color: isListening
                        ? AppColors.of(context).bioAccent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.6),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Main morphing blob button
              Transform.scale(
                scale: isListening
                    ? 1.0 + _activeAnim.value * 0.08
                    : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _buttonColor,
                    borderRadius: _morphBorderRadius(_morphAnim.value),
                    boxShadow: [
                      BoxShadow(
                        color: _buttonColor.withValues(alpha: 0.3),
                        blurRadius: isListening ? 24 : 10,
                        spreadRadius: isListening ? 4 : 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isListening
                          ? const Icon(
                              Icons.stop_rounded,
                              color: Colors.white,
                              size: 26,
                              key: ValueKey('stop'),
                            )
                          : Container(
                              key: const ValueKey('dot'),
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
