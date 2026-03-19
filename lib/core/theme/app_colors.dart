import 'package:flutter/material.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color paper;
  final Color cream;
  final Color cardSurface;
  final Color charcoal;
  final Color inkLight;
  final Color mutedText;
  final Color borderLight;
  
  final Color bioAccent;
  final Color bioGlow;
  final Color bioPulse;
  final Color bioMint;
  final Color bioAmber;

  final Color tagActionable;
  final Color tagData;
  final Color tagInsight;
  final Color tagProcessing;

  final Color glassFill;
  final Color glassBorder;

  const AppColorsExtension({
    required this.paper,
    required this.cream,
    required this.cardSurface,
    required this.charcoal,
    required this.inkLight,
    required this.mutedText,
    required this.borderLight,
    required this.bioAccent,
    required this.bioGlow,
    required this.bioPulse,
    required this.bioMint,
    required this.bioAmber,
    required this.tagActionable,
    required this.tagData,
    required this.tagInsight,
    required this.tagProcessing,
    required this.glassFill,
    required this.glassBorder,
  });

  @override
  AppColorsExtension copyWith({
    Color? paper, Color? cream, Color? cardSurface, 
    Color? charcoal, Color? inkLight, Color? mutedText, Color? borderLight,
    Color? bioAccent, Color? bioGlow, Color? bioPulse, Color? bioMint, Color? bioAmber,
    Color? tagActionable, Color? tagData, Color? tagInsight, Color? tagProcessing,
    Color? glassFill, Color? glassBorder,
  }) {
    return AppColorsExtension(
      paper: paper ?? this.paper,
      cream: cream ?? this.cream,
      cardSurface: cardSurface ?? this.cardSurface,
      charcoal: charcoal ?? this.charcoal,
      inkLight: inkLight ?? this.inkLight,
      mutedText: mutedText ?? this.mutedText,
      borderLight: borderLight ?? this.borderLight,
      bioAccent: bioAccent ?? this.bioAccent,
      bioGlow: bioGlow ?? this.bioGlow,
      bioPulse: bioPulse ?? this.bioPulse,
      bioMint: bioMint ?? this.bioMint,
      bioAmber: bioAmber ?? this.bioAmber,
      tagActionable: tagActionable ?? this.tagActionable,
      tagData: tagData ?? this.tagData,
      tagInsight: tagInsight ?? this.tagInsight,
      tagProcessing: tagProcessing ?? this.tagProcessing,
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      paper: Color.lerp(paper, other.paper, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      charcoal: Color.lerp(charcoal, other.charcoal, t)!,
      inkLight: Color.lerp(inkLight, other.inkLight, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      borderLight: Color.lerp(borderLight, other.borderLight, t)!,
      bioAccent: Color.lerp(bioAccent, other.bioAccent, t)!,
      bioGlow: Color.lerp(bioGlow, other.bioGlow, t)!,
      bioPulse: Color.lerp(bioPulse, other.bioPulse, t)!,
      bioMint: Color.lerp(bioMint, other.bioMint, t)!,
      bioAmber: Color.lerp(bioAmber, other.bioAmber, t)!,
      tagActionable: Color.lerp(tagActionable, other.tagActionable, t)!,
      tagData: Color.lerp(tagData, other.tagData, t)!,
      tagInsight: Color.lerp(tagInsight, other.tagInsight, t)!,
      tagProcessing: Color.lerp(tagProcessing, other.tagProcessing, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
    );
  }
}

class AppColors {
  AppColors._();

  // === Default definitions (Light) ===
  static const light = AppColorsExtension(
    paper: Color(0xFFFAF9F6),
    cream: Color(0xFFF9F7F2),
    cardSurface: Color(0xFFE5E3D8), // Slightly darker for visible contrast in light mode
    charcoal: Color(0xFF1A1A1A),
    inkLight: Color(0xFF3A3A3A),
    mutedText: Color(0xFFA0A09F),
    borderLight: Color(0xFFE5E3DE),
    bioAccent: Color(0xFF6B7280),
    bioGlow: Color(0xFF9CA3AF),
    bioPulse: Color(0xFF4B5563),
    bioMint: Color(0xFF10B981),
    bioAmber: Color(0xFFF59E0B),
    tagActionable: Color(0xFF1A1A1A),
    tagData: Color(0xFF059669),
    tagInsight: Color(0xFF6B7280),
    tagProcessing: Color(0xFFC0C0C0),
    glassFill: Color(0x99FFFFFF),
    glassBorder: Color(0x66FFFFFF),
  );

  // System Globals
  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);

  // Dark theme definition
  static const dark = AppColorsExtension(
    paper: Color(0xFF030303),
    cream: Color(0xFF121212),
    cardSurface: Color(0xFF1A1A1A),
    charcoal: Color(0xFFF5F5F7),
    inkLight: Color(0xFFB0B0B5),
    mutedText: Color(0xFF75757A),
    borderLight: Color(0xFF2A2A2A),
    bioAccent: Color(0xFF94A3B8),
    bioGlow: Color(0xFF64748B),
    bioPulse: Color(0xFFCBD5E1),
    bioMint: Color(0xFF10B981),
    bioAmber: Color(0xFFF59E0B),
    tagActionable: Color(0xFFF5F5F7),
    tagData: Color(0xFF059669),
    tagInsight: Color(0xFF94A3B8),
    tagProcessing: Color(0xFF404040),
    glassFill: Color(0x991A1A1A),
    glassBorder: Color(0x33FFFFFF),
  );

  // Helper extension to get colors seamlessly - respects theme mode
  static AppColorsExtension of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }
}
