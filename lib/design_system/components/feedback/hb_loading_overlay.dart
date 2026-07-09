import 'package:flutter/material.dart';

import '../../design_system.dart';

class HBLoadingOverlay extends StatelessWidget {
  const HBLoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: AppColors.background.withValues(alpha: 0.72),
              child: Semantics(
                container: true,
                liveRegion: true,
                label: message ?? 'Carregando',
                child: HBLoading(message: message),
              ),
            ),
          ),
      ],
    );
  }
}
