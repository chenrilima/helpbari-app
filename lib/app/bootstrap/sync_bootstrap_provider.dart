import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/charts/presentation/providers/chart_series_providers.dart';
import '../../features/home/presentation/providers/home_view_model_provider.dart';
import '../../features/progress/presentation/providers/progress_view_model_provider.dart';
import '../../features/water/presentation/providers/water_view_model_provider.dart';

final syncBootstrapProvider = Provider<void>((ref) {
  String? lastSyncedUserId;

  Future<void> refreshConsumers() async {
    ref.invalidate(waterChartSeriesProvider);
    ref.invalidate(healthScoreChartSeriesProvider);
    await Future.wait([
      ref.read(waterViewModelProvider.notifier).loadHistory(),
      ref.read(homeViewModelProvider.notifier).loadHome(),
      ref.read(progressViewModelProvider.notifier).loadProgress(),
    ]);
  }

  Future<void> synchronize(String userId) async {
    if (lastSyncedUserId == userId) return;
    lastSyncedUserId = userId;

    await ref.read(syncManagerProvider.notifier).loadState();
    await ref.read(syncManagerProvider.notifier).syncNow();
  }

  ref.listen(syncManagerProvider, (previous, next) {
    if (previous?.isSyncing == true && !next.isSyncing) {
      unawaited(refreshConsumers());
    }
  });

  ref.listen(authSessionProvider, (previous, next) {
    if (next == null) {
      lastSyncedUserId = null;
      return;
    }
    unawaited(synchronize(next.id));
  }, fireImmediately: true);
});
