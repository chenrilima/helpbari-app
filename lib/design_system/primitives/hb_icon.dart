import 'package:flutter/material.dart';

import '../theme/theme.dart';

class HBIcon extends StatelessWidget {
  const HBIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = AppSizes.iconMd,
    this.semanticLabel,
  });

  final IconData icon;
  final Color? color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(
      icon,
      color: color ?? AppColors.textPrimary,
      size: size,
    );

    if (semanticLabel == null) {
      return ExcludeSemantics(child: iconWidget);
    }

    return Semantics(label: semanticLabel, image: true, child: iconWidget);
  }
}
