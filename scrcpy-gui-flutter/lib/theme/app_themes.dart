import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color bgColor;
  final Color glassBg;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentGlow;
  final Color accentSoft;
  final Color textMain;
  final Color textMuted;
  final Color borderColor;
  final Color inputBg;
  final Color surfaceColor;

  const AppTheme({
    required this.name,
    required this.bgColor,
    required this.glassBg,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentGlow,
    required this.accentSoft,
    required this.textMain,
    required this.textMuted,
    required this.borderColor,
    required this.inputBg,
    required this.surfaceColor,
  });
}

class AppThemes {
  static const ultraviolet = AppTheme(
    name: 'Ultraviolet',
    bgColor: Color(0xFF0C0C0E),
    glassBg: Color(0xB318181B),
    accentPrimary: Color(0xFFBC6FF1),
    accentSecondary: Color(0xFF892CDC),
    accentGlow: Color(0x66BC6FF1),
    accentSoft: Color(0x1ABC6FF1),
    textMain: Color(0xFFF1F5F9),
    textMuted: Color(0xFF71717A),
    borderColor: Color(0x26BC6FF1),
    inputBg: Color(0xFF0C0C0E),
    surfaceColor: Color(0xFF18181B),
  );

  static const astro = AppTheme(
    name: 'Astro Blue',
    bgColor: Color(0xFF020617),
    glassBg: Color(0xB30F172A),
    accentPrimary: Color(0xFF06B6D4),
    accentSecondary: Color(0xFF0891B2),
    accentGlow: Color(0x6606B6D4),
    accentSoft: Color(0x1A06B6D4),
    textMain: Color(0xFFF1F5F9),
    textMuted: Color(0xFF71717A),
    borderColor: Color(0x2606B6D4),
    inputBg: Color(0xFF020617),
    surfaceColor: Color(0xFF0F172A),
  );

  static const carbon = AppTheme(
    name: 'Carbon Stealth',
    bgColor: Color(0xFF09090B),
    glassBg: Color(0xB318181B),
    accentPrimary: Color(0xFFFFFFFF),
    accentSecondary: Color(0xFFA1A1AA),
    accentGlow: Color(0x1AFFFFFF),
    accentSoft: Color(0x0DFFFFFF),
    textMain: Color(0xFFF1F5F9),
    textMuted: Color(0xFF71717A),
    borderColor: Color(0x26FFFFFF),
    inputBg: Color(0xFF09090B),
    surfaceColor: Color(0xFF18181B),
  );

  static const emerald = AppTheme(
    name: 'Emerald Stealth',
    bgColor: Color(0xFF09090B),
    glassBg: Color(0xB318181B),
    accentPrimary: Color(0xFF10B981),
    accentSecondary: Color(0xFF059669),
    accentGlow: Color(0x6610B981),
    accentSoft: Color(0x1A10B981),
    textMain: Color(0xFFF1F5F9),
    textMuted: Color(0xFF71717A),
    borderColor: Color(0x2610B981),
    inputBg: Color(0xFF09090B),
    surfaceColor: Color(0xFF18181B),
  );

  static const bloodmoon = AppTheme(
    name: 'Blood Moon',
    bgColor: Color(0xFF0A0000),
    glassBg: Color(0xB3140000),
    accentPrimary: Color(0xFFEF4444),
    accentSecondary: Color(0xFF991B1B),
    accentGlow: Color(0x66EF4444),
    accentSoft: Color(0x1AEF4444),
    textMain: Color(0xFFF1F5F9),
    textMuted: Color(0xFF71717A),
    borderColor: Color(0x26EF4444),
    inputBg: Color(0xFF0A0000),
    surfaceColor: Color(0xFF140000),
  );

  static const all = [ultraviolet, astro, carbon, emerald, bloodmoon];
  static const keys = ['ultraviolet', 'astro', 'carbon', 'emerald', 'bloodmoon'];

  static AppTheme fromKey(String key) {
    switch (key) {
      case 'astro': return astro;
      case 'carbon': return carbon;
      case 'emerald': return emerald;
      case 'bloodmoon': return bloodmoon;
      default: return ultraviolet;
    }
  }
}
