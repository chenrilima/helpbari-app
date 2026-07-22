import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class BariaGlobalOverlay extends StatelessWidget {
  const BariaGlobalOverlay({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Overlay(
    key: ObjectKey(child),
    initialEntries: <OverlayEntry>[OverlayEntry(builder: (_) => child)],
  );
}

class BariaFab extends StatelessWidget {
  const BariaFab({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Abrir assistente BarIA',
      child: FloatingActionButton(
        heroTag: 'global-baria-fab',
        tooltip: 'BarIA',
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }
}
