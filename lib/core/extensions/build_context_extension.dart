import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

extension BuildContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => Theme.of(this).textTheme;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => mediaQuery.size;

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  bool get isCompact => screenWidth < AppBreakpoints.medium;

  bool get isMedium {
    return screenWidth >= AppBreakpoints.medium &&
        screenWidth < AppBreakpoints.expanded;
  }

  bool get isExpanded => screenWidth >= AppBreakpoints.expanded;

  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(content: Text(message)));
  }
}
