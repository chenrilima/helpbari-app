import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HBText(
              'HelpBari',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const HBGap.md(),
            HBText(
              'Preparando sua jornada...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const HBGap.xl(),
            const HBLoading(),
          ],
        ),
      ],
    );
  }
}
