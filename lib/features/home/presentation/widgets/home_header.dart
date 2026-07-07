import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({required this.userName, super.key});

  final String userName;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final greeting = switch (now.hour) {
      >= 5 && < 12 => '☀️ Bom dia',
      >= 12 && < 18 => '🌤️ Boa tarde',
      _ => '🌙 Boa noite',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          '$greeting, $userName',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const HBGap.sm(),
        HBText(
          'Vamos acompanhar sua evolução hoje.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
