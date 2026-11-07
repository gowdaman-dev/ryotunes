import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

class RyotunesTheme {
  static ThemeData light() => _build(
        paper: RyColors.lightPaper,
        paperLift: RyColors.lightPaperLift,
        ink: RyColors.lightInk,
        inkDim: RyColors.lightInkDim,
        inkMuted: RyColors.lightInkMuted,
        inkFaint: RyColors.lightInkFaint,
        bone: RyColors.lightBone,
        inkOnBone: RyColors.lightInkOnBone,
        sun: RyColors.lightSun,
        alert: RyColors.lightAlert,
        line: RyColors.lightLine,
        lineSoft: RyColors.lightLineSoft,
        lineStrong: RyColors.lightLineStrong,
        tint5: RyColors.lightTint5,
        brightness: Brightness.light,
      );

  static ThemeData dark() => _build(
        paper: RyColors.darkPaper,
        paperLift: RyColors.darkPaperLift,
        ink: RyColors.darkInk,
        inkDim: RyColors.darkInkDim,
        inkMuted: RyColors.darkInkMuted,
        inkFaint: RyColors.darkInkFaint,
        bone: RyColors.darkBone,
        inkOnBone: RyColors.darkInkOnBone,
        sun: RyColors.darkSun,
        alert: RyColors.darkAlert,
        line: RyColors.darkLine,
        lineSoft: RyColors.darkLineSoft,
        lineStrong: RyColors.darkLineStrong,
        tint5: RyColors.darkTint5,
        brightness: Brightness.dark,
      );

  static ThemeData _build({
    required Color paper,
    required Color paperLift,
    required Color ink,
    required Color inkDim,
    required Color inkMuted,
    required Color inkFaint,
    required Color bone,
    required Color inkOnBone,
    required Color sun,
    required Color alert,
    required Color line,
    required Color lineSoft,
    required Color lineStrong,
    required Color tint5,
    required Brightness brightness,
  }) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: sun,
      onPrimary: inkOnBone,
      secondary: bone,
      onSecondary: inkOnBone,
      tertiary: inkDim,
      onTertiary: paper,
      error: alert,
      onError: paper,
      surface: paper,
      onSurface: ink,
      surfaceContainerLowest: paper,
      surfaceContainerLow: paper,
      surfaceContainer: paperLift,
      surfaceContainerHigh: paperLift,
      surfaceContainerHighest: paperLift,
      outline: lineStrong,
      outlineVariant: line,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paper,
      canvasColor: paper,
      textTheme: TextTheme(
        displayLarge: RyFonts.display(TypeScale.hero, color: ink),
        displayMedium: RyFonts.display(TypeScale.title, color: ink),
        headlineLarge: RyFonts.display(TypeScale.xl, color: ink),
        headlineMedium: RyFonts.ui(TypeScale.lg, weight: FontWeight.w500, color: ink),
        titleLarge: RyFonts.ui(TypeScale.lg, weight: FontWeight.w500, color: ink),
        titleMedium: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: ink),
        bodyLarge: RyFonts.ui(TypeScale.md, color: ink),
        bodyMedium: RyFonts.ui(TypeScale.sm, color: inkDim),
        bodySmall: RyFonts.ui(TypeScale.xs, color: inkMuted),
        labelLarge: RyFonts.ui(TypeScale.sm, weight: FontWeight.w500, color: ink),
        labelSmall: RyFonts.mono(TypeScale.micro, color: inkFaint, letterSpacing: 1.4),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: RyFonts.ui(TypeScale.lg, weight: FontWeight.w500, color: ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: paperLift,
        indicatorColor: sun.withValues(alpha: 0.16),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return IconThemeData(color: sun, size: 22);
          return IconThemeData(color: inkMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return RyFonts.ui(TypeScale.xs, weight: FontWeight.w500, color: sun);
          return RyFonts.ui(TypeScale.xs, color: inkMuted);
        }),
        height: 64,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: Stroke.hairline, space: 0),
      cardTheme: CardThemeData(
        color: paperLift,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: BorderSide(color: line, width: Stroke.hairline),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tint5,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: BorderSide(color: sun, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: RyFonts.ui(TypeScale.sm, color: inkMuted),
      ),
      iconTheme: IconThemeData(color: ink, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: inkMuted,
        textColor: ink,
        titleTextStyle: RyFonts.ui(TypeScale.md, weight: FontWeight.w500, color: ink),
        subtitleTextStyle: RyFonts.ui(TypeScale.sm, color: inkDim),
      ),
    );
  }
}