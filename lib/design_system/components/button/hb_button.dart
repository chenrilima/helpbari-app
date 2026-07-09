import 'package:flutter/material.dart';

import '../../design_system.dart';

class HBButton extends StatelessWidget {
  const HBButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.isLoading = false,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    final effectiveLabel = semanticLabel ?? label;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      liveRegion: isLoading,
      label: isLoading ? '$effectiveLabel, carregando' : effectiveLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.disabled,
            disabledForegroundColor: AppColors.textDisabled,
            minimumSize: const Size.fromHeight(AppSizes.buttonMinTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            textStyle: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppColors.onPrimary),
          ),
          child: isLoading
              ? const ExcludeSemantics(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  ),
                )
              : _HBButtonContent(label: label, icon: icon),
        ),
      ),
    );
  }
}

class _HBButtonContent extends StatelessWidget {
  const _HBButtonContent({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(label);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm),
        const HBGap.horizontal(AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
