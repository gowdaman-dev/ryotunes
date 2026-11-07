import 'package:flutter/material.dart';
import '../theme/spacing.dart';

class Hairline extends StatelessWidget {
  final double? height;
  const Hairline({super.key, this.height});
  @override
  Widget build(BuildContext context) {
    return Container(height: height ?? Stroke.hairline, color: Theme.of(context).colorScheme.outlineVariant);
  }
}