import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import 'bootstrap/sync_bootstrap_provider.dart';
import 'router/app_router.dart';

class HelpBariApp extends ConsumerStatefulWidget {
  const HelpBariApp({super.key});

  @override
  ConsumerState<HelpBariApp> createState() => _HelpBariAppState();
}

class _HelpBariAppState extends ConsumerState<HelpBariApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncBootstrapProvider).onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncBootstrapProvider);
    return MaterialApp.router(
      title: 'HelpBari',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
