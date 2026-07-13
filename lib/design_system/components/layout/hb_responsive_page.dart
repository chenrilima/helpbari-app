import 'package:flutter/material.dart';

import '../../design_system.dart';

class HBResponsivePage extends StatelessWidget {
  const HBResponsivePage({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.scrollable = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth >= AppBreakpoints.medium
              ? AppBreakpoints.medium
              : double.infinity;

          final constrainedChild = Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
          if (scrollable) {
            return SingleChildScrollView(
              padding: padding,
              child: constrainedChild,
            );
          }
          return Padding(padding: padding, child: constrainedChild);
        },
      ),
    );
  }
}
