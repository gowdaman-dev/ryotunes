import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypeScale {
  static const double micro = 10;
  static const double xs = 11;
  static const double sm = 13;
  static const double md = 15;
  static const double lg = 18;
  static const double xl = 24;
  static const double title = 36;
  static const double hero = 34;
}

class RyFonts {
  static TextStyle ui(double size, {FontWeight weight = FontWeight.w400, Color? color, double? letterSpacing, double? height}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height);

  static TextStyle display(double size, {FontWeight weight = FontWeight.w800, Color? color, double? letterSpacing}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing ?? -0.6);

  static TextStyle mono(double size, {FontWeight weight = FontWeight.w400, Color? color, double? letterSpacing, double? height}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, letterSpacing: letterSpacing, height: height, fontFeatures: const [FontFeature.tabularFigures()]);
}