import 'package:flutter/material.dart';

abstract final class AppShadows {
  static List<BoxShadow> get soft {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
    ];
  }

  static List<BoxShadow> get medium {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 32,
        offset: const Offset(0, 16),
      ),
    ];
  }
}
