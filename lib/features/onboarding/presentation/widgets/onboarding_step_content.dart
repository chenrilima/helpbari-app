import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class OnboardingStepContent extends StatelessWidget {
  const OnboardingStepContent({
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Column(
        key: ValueKey(title),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 32),
          ),
          const HBGap.xl(),
          HBText(title, style: Theme.of(context).textTheme.headlineSmall),
          const HBGap.md(),
          HBText(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const HBGap.xl(),
          ...children,
        ],
      ),
    );
  }
}
