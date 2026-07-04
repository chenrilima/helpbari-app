import 'package:flutter/material.dart';
import '../../design_system.dart';

class HBScaffold extends StatelessWidget {
  const HBScaffold({
    required this.child,
    super.key,
    this.backgroundColor = AppColors.background,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.appBar,
    this.floatingActionButton,
  });

  final Widget child;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      body: HBResponsivePage(padding: padding, child: child),
    );
  }
}
