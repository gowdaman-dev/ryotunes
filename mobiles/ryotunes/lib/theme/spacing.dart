/// Spacing scale: 4px grid (matches desktop Style.sp(n) = n*4).
class Sp {
  static const double unit = 4.0;
  static double sp(int n) => n * unit;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double pagePad = 20;
}

/// Radii — compact, not inflated pills.
class Radii {
  static const double control = 8;
  static const double card = 14;
  static const double hero = 20;
  static const double sheet = 20;
  static const double pill = 999;
}

/// Stroke widths.
class Stroke {
  static const double hairline = 1.0;
}

/// Bottom scroll padding so content clears the floating mini-player + tab bar.
const double kShellBottomInset = 168;
