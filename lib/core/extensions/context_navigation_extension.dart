import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

extension ContextNavigationExtension on BuildContext {
  Future<T?> pushAndRefresh<T>(
    String route, {
    Future<void> Function()? onRefresh,
    bool Function(T? result)? shouldRefresh,
  }) async {
    final result = await push<T>(route);

    if (!mounted) return result;

    final canRefresh = shouldRefresh?.call(result) ?? true;

    if (canRefresh) {
      await onRefresh?.call();
    }

    return result;
  }
}
