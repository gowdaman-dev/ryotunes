import 'package:flutter/material.dart';

/// Provider brand colors (desktop Style.providerColors).
class ProviderColors {
  static const youtube = Color(0xFFFF2D2D);
  static const spotify = Color(0xFF1DB954);
  static const soundcloud = Color(0xFFFF5500);
  static const tidal = Color(0xFF4FC3DC);
  static Color forProvider(String p) {
    switch (p) {
      case 'spotify': return spotify;
      case 'soundcloud': return soundcloud;
      case 'tidal': return tidal;
      default: return youtube;
    }
  }
}

/// Ryotunes mobile color tokens — clean system surfaces with a single red accent.
class RyColors {
  static const accent = Color(0xFFFA2D48);

  // Dark mode
  static const darkPaper = Color(0xFF000000);
  static const darkPaperLift = Color(0xFF1C1C1E);
  static const darkInk = Color(0xFFFFFFFF);
  static const darkInkDim = Color(0xFFD1D1D6);
  static const darkInkMuted = Color(0xFF8E8E93);
  static const darkInkFaint = Color(0xFF636366);
  static const darkBone = Color(0xFFFFFFFF);
  static const darkInkOnBone = Color(0xFF000000);
  static const darkSun = accent;
  static const darkAlert = Color(0xFFFF453A);
  static const darkLine = Color(0x33FFFFFF);
  static const darkLineSoft = Color(0x1AFFFFFF);
  static const darkLineStrong = Color(0x66FFFFFF);
  static const darkTint5 = Color(0x0DFFFFFF);
  static const darkTint10 = Color(0x1AFFFFFF);
  static const darkTint16 = Color(0x29FFFFFF);

  // Light mode
  static const lightPaper = Color(0xFFFFFFFF);
  static const lightPaperLift = Color(0xFFF2F2F7);
  static const lightInk = Color(0xFF000000);
  static const lightInkDim = Color(0xFF3C3C43);
  static const lightInkMuted = Color(0xFF8E8E93);
  static const lightInkFaint = Color(0xFFAEAEB2);
  static const lightBone = Color(0xFF000000);
  static const lightInkOnBone = Color(0xFFFFFFFF);
  static const lightSun = accent;
  static const lightAlert = Color(0xFFFF3B30);
  static const lightLine = Color(0x33000000);
  static const lightLineSoft = Color(0x1F000000);
  static const lightLineStrong = Color(0x66000000);
  static const lightTint5 = Color(0x0D000000);
  static const lightTint10 = Color(0x1A000000);
  static const lightTint16 = Color(0x29000000);

  static bool paperDark(Color paper) => (paper.r + paper.g + paper.b) / 3 < 0.5;
}
