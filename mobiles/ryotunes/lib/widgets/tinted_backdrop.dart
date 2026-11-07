import 'package:flutter/material.dart';
import '../util/artwork_color.dart';

/// Page background that fades from a tint taken from [imageUrl] into the normal surface colour.
class TintedBackdrop extends StatefulWidget {
  final String? imageUrl;
  final Widget child;
  const TintedBackdrop({super.key, required this.imageUrl, required this.child});

  @override
  State<TintedBackdrop> createState() => _TintedBackdropState();
}

class _TintedBackdropState extends State<TintedBackdrop> {
  Color? _tint;
  String? _for;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant TintedBackdrop old) {
    super.didUpdateWidget(old);
    _resolve();
  }

  void _resolve() {
    final url = widget.imageUrl;
    if (url == null || url == _for) return;
    _for = url;
    artworkColor(url).then((c) {
      if (c != null && mounted && _for == url) setState(() => _tint = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tint = _tint ?? surface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(surface, tint, dark ? 0.65 : 0.4)!, surface],
          stops: const [0, 0.55],
        ),
      ),
      child: widget.child,
    );
  }
}
