import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'glass.dart';

/// Floating circular back button for pages with a full-bleed header.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/'),
        child: Glass(radius: 22, blur: 18, width: 44, height: 44, child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: scheme.onSurface)),
      ),
    );
  }
}
