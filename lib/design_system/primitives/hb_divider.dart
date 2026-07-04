import 'package:flutter/material.dart';

import '../theme/theme.dart';

class HBDivider extends StatelessWidget {
  const HBDivider({super.key, this.height = AppSpacing.lg});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Divider(height: height, color: AppColors.border, thickness: 1);
  }
}
