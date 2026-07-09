import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../providers/water_view_model_provider.dart';

class RegisterWaterPage extends ConsumerWidget {
  const RegisterWaterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return HBPage(
      appBar: const HBAppBar(
        title: 'Registrar água',
        subtitle: 'Acompanhe sua hidratação',
      ),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _QuickWaterButton(label: '200 ml', amount: 200),
            _QuickWaterButton(label: '300 ml', amount: 300),
            _QuickWaterButton(label: '500 ml', amount: 500),
            _QuickWaterButton(label: '750 ml', amount: 750),
          ],
        ),
        const HBGap.xl(),
        HBButton(
          label: 'Quantidade personalizada',
          onPressed: () {
            // Implementaremos depois.
          },
        ),
      ],
    );
  }
}

class _QuickWaterButton extends ConsumerWidget {
  const _QuickWaterButton({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 160,
      child: HBButton(
        label: label,
        icon: AppIcons.water,
        onPressed: () async {
          await ref.read(waterViewModelProvider.notifier).registerWater(amount);
          if (!context.mounted) return;
          HBSnackBar.success(context, message: '$label registrado! 💧');
          context.pop(true);
        },
      ),
    );
  }
}
