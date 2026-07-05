import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      children: [
        HBCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HBText(
                'Complete seu perfil',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const HBGap.sm(),
              HBText(
                'Essas informações ajudarão o HelpBari a acompanhar sua evolução de forma personalizada.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const HBGap.xl(),
              HBButton(label: 'Continuar', onPressed: () {}),
            ],
          ),
        ),
      ],
    );
  }
}
