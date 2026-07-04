import 'package:flutter/material.dart';

import '../theme/theme.dart';

class HBIcon extends StatelessWidget {
  const HBIcon(this.icon, {super.key, this.color, this.size = AppSizes.iconMd});

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color ?? AppColors.textPrimary, size: size);
  }
}
