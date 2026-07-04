import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

class HBGap extends StatelessWidget {
  const HBGap.vertical(this.size, {super.key}) : horizontal = false;

  const HBGap.horizontal(this.size, {super.key}) : horizontal = true;

  const HBGap.xs({super.key}) : size = AppSpacing.xs, horizontal = false;

  const HBGap.sm({super.key}) : size = AppSpacing.sm, horizontal = false;

  const HBGap.md({super.key}) : size = AppSpacing.md, horizontal = false;

  const HBGap.lg({super.key}) : size = AppSpacing.lg, horizontal = false;

  const HBGap.xl({super.key}) : size = AppSpacing.xl, horizontal = false;

  final double size;

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return SizedBox(width: size);
    }

    return SizedBox(height: size);
  }
}
