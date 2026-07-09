import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    required this.value,
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  final double value;
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Etapa $currentStep de $totalSteps',
      value: '${(value * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBText(
            'Etapa $currentStep de $totalSteps',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const HBGap.sm(),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: AppColors.primaryLight,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
