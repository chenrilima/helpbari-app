import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'router/app_router.dart';

class HelpBariApp extends StatelessWidget {
  const HelpBariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'HelpBari',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
