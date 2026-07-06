import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class HomeSection extends StatelessWidget {
  const HomeSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: HBText(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            ?action,
          ],
        ),

        if (subtitle != null) ...[
          const HBGap.xs(),
          HBText(
            subtitle!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],

        const HBGap.md(),

        child,
      ],
    );
  }
}
