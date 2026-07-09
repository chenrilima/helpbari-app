import 'package:flutter/material.dart';

import '../../design_system.dart';

enum HBDialogType { info, success, warning, error }

abstract final class HBDialog {
  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    String? semanticLabel,
  }) {
    return _showMessage(
      context,
      type: HBDialogType.info,
      title: title,
      message: message,
      actionLabel: actionLabel,
      semanticLabel: semanticLabel,
    );
  }

  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    String? semanticLabel,
  }) {
    return _showMessage(
      context,
      type: HBDialogType.success,
      title: title,
      message: message,
      actionLabel: actionLabel,
      semanticLabel: semanticLabel,
    );
  }

  static Future<void> warning(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    String? semanticLabel,
  }) {
    return _showMessage(
      context,
      type: HBDialogType.warning,
      title: title,
      message: message,
      actionLabel: actionLabel,
      semanticLabel: semanticLabel,
    );
  }

  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String actionLabel = 'OK',
    String? semanticLabel,
  }) {
    return _showMessage(
      context,
      type: HBDialogType.error,
      title: title,
      message: message,
      actionLabel: actionLabel,
      semanticLabel: semanticLabel,
    );
  }

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Cancelar',
    HBDialogType type = HBDialogType.warning,
    bool barrierDismissible = true,
    String? semanticLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) {
        return _HBDialogContent(
          type: type,
          title: title,
          message: message,
          primaryLabel: confirmLabel,
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
          secondaryLabel: cancelLabel,
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
          semanticLabel: semanticLabel,
        );
      },
    );
  }

  static Future<void> _showMessage(
    BuildContext context, {
    required HBDialogType type,
    required String title,
    required String message,
    required String actionLabel,
    String? semanticLabel,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _HBDialogContent(
          type: type,
          title: title,
          message: message,
          primaryLabel: actionLabel,
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(),
          semanticLabel: semanticLabel,
        );
      },
    );
  }
}

class _HBDialogContent extends StatelessWidget {
  const _HBDialogContent({
    required this.type,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.semanticLabel,
  });

  final HBDialogType type;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimaryPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = _color(type);

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: semanticLabel ?? '$title. $message',
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.pageMaxWidth),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: AppSizes.avatarLg,
                    height: AppSizes.avatarLg,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Icon(
                      _icon(type),
                      color: color,
                      size: AppSizes.iconLg,
                    ),
                  ),
                ),
                const HBGap.lg(),
                HBText(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const HBGap.sm(),
                HBText(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const HBGap.lg(),
                HBButton(label: primaryLabel, onPressed: onPrimaryPressed),
                if (secondaryLabel != null && onSecondaryPressed != null) ...[
                  const HBGap.sm(),
                  _HBDialogSecondaryButton(
                    label: secondaryLabel!,
                    onPressed: onSecondaryPressed!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _color(HBDialogType type) {
    return switch (type) {
      HBDialogType.info => AppColors.info,
      HBDialogType.success => AppColors.success,
      HBDialogType.warning => AppColors.warning,
      HBDialogType.error => AppColors.danger,
    };
  }

  static IconData _icon(HBDialogType type) {
    return switch (type) {
      HBDialogType.info => Icons.info_outline,
      HBDialogType.success => Icons.check_circle_outline,
      HBDialogType.warning => Icons.warning_amber_outlined,
      HBDialogType.error => Icons.error_outline,
    };
  }
}

class _HBDialogSecondaryButton extends StatelessWidget {
  const _HBDialogSecondaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeight,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            minimumSize: const Size.fromHeight(AppSizes.buttonMinTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            textStyle: Theme.of(context).textTheme.labelLarge,
          ),
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
