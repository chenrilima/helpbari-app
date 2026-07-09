import 'package:flutter/material.dart';

import '../../design_system.dart';

enum HBSnackBarType { success, error, warning, info }

abstract final class HBSnackBar {
  static void success(BuildContext context, {required String message}) {
    show(context, message: message, type: HBSnackBarType.success);
  }

  static void error(BuildContext context, {required String message}) {
    show(context, message: message, type: HBSnackBarType.error);
  }

  static void warning(BuildContext context, {required String message}) {
    show(context, message: message, type: HBSnackBarType.warning);
  }

  static void info(BuildContext context, {required String message}) {
    show(context, message: message, type: HBSnackBarType.info);
  }

  static void show(
    BuildContext context, {
    required String message,
    HBSnackBarType type = HBSnackBarType.info,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _backgroundColor(type),
        content: Semantics(
          container: true,
          liveRegion: true,
          label: message,
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  _icon(type),
                  color: AppColors.onPrimary,
                  size: AppSizes.iconSm,
                ),
              ),
              const HBGap.horizontal(AppSpacing.sm),
              Expanded(
                child: HBText(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.md),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static Color _backgroundColor(HBSnackBarType type) {
    return switch (type) {
      HBSnackBarType.success => AppColors.success,
      HBSnackBarType.error => AppColors.danger,
      HBSnackBarType.warning => AppColors.warning,
      HBSnackBarType.info => AppColors.primary,
    };
  }

  static IconData _icon(HBSnackBarType type) {
    return switch (type) {
      HBSnackBarType.success => Icons.check_circle_outline,
      HBSnackBarType.error => Icons.error_outline,
      HBSnackBarType.warning => Icons.warning_amber_outlined,
      HBSnackBarType.info => Icons.info_outline,
    };
  }
}
