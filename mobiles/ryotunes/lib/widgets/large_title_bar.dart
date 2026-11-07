import 'package:flutter/material.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'account_sheet.dart';

/// Big bold page title with the profile avatar on the right (Apple Music style).
class LargeTitleBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showLogo;
  const LargeTitleBar({super.key, required this.title, this.subtitle, this.trailing, this.showLogo = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(Sp.pagePad, MediaQuery.of(context).padding.top + 14, Sp.pagePad, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showLogo) ...[
            ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.asset('assets/brand/logo.png', width: 46, height: 46, filterQuality: FilterQuality.medium)),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: RyFonts.display(36, color: scheme.onSurface, letterSpacing: -1)),
                if (subtitle != null)
                  Text(subtitle!, style: RyFonts.ui(TypeScale.md, color: scheme.onSurface.withValues(alpha: 0.55))),
              ],
            ),
          ),
          trailing ?? const ProfileAvatar(),
        ],
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
        builder: (_) => const AccountSheet(),
      ),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8FA3E8), Color(0xFF7B5CC4)]),
        ),
        child: Text('RY', style: RyFonts.ui(TypeScale.md, weight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }
}
