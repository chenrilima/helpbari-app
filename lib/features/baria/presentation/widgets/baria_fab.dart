import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class BariaGlobalOverlay extends StatefulWidget {
  const BariaGlobalOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<BariaGlobalOverlay> createState() => _BariaGlobalOverlayState();
}

class _BariaGlobalOverlayState extends State<BariaGlobalOverlay> {
  late final OverlayEntry _entry;

  @override
  void initState() {
    super.initState();
    _entry = OverlayEntry(builder: (_) => widget.child);
  }

  @override
  void didUpdateWidget(BariaGlobalOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) =>
      Overlay(initialEntries: <OverlayEntry>[_entry]);
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
