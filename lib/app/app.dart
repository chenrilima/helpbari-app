import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/baria/presentation/widgets/baria_fab.dart';
import '../features/baria/presentation/widgets/baria_sheet.dart';
import 'bootstrap/sync_bootstrap_provider.dart';
import 'bootstrap/notification_bootstrap_provider.dart';
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
      ref.read(notificationBootstrapProvider).onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(syncBootstrapProvider);
    ref.watch(notificationBootstrapProvider);
    final router = ref.watch(appRouterProvider);
    final isAuthenticated = ref.watch(authSessionProvider) != null;
    return MaterialApp.router(
      title: 'HelpBari',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => BariaGlobalOverlay(
        child: AnimatedBuilder(
          animation: router.routeInformationProvider,
          builder: (context, _) {
            final String path = router.routeInformationProvider.value.uri.path;
            const hiddenPaths = <String>{
              '/',
              '/onboarding',
              '/login',
              '/sign-up',
              '/reset-password',
              '/complete-profile',
              '/baria',
            };
            return Stack(
              children: [
                ?child,
                if (isAuthenticated && !hiddenPaths.contains(path))
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: BariaFab(
                      onPressed: () {
                        final navigatorContext =
                            rootNavigatorKey.currentContext;
                        if (navigatorContext != null) {
                          BariaSheet.show(navigatorContext);
                        }
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
