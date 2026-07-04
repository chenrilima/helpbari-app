import 'package:flutter/material.dart';

import '../components/layout/layout.dart';
import '../primitives/primitives.dart';
import '../theme/theme.dart';

class HBPage extends StatelessWidget {
  const HBPage({
    required this.children,
    super.key,
    this.appBar,
    this.header,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final PreferredSizeWidget? appBar;
  final Widget? header;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return HBScaffold(
      appBar: appBar,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null) ...[header!, const HBGap.xl()],
          ...children,
        ],
      ),
    );
  }
}
