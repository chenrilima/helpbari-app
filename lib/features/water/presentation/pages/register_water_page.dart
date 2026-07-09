import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formatters/app_water_formatter.dart';
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
            _QuickWaterButton(amount: 200),
            _QuickWaterButton(amount: 300),
            _QuickWaterButton(amount: 500),
            _QuickWaterButton(amount: 750),
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
  const _QuickWaterButton({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = AppWaterFormatter.ml(amount);

    return SizedBox(
      width: 160,
      child: HBButton(
        label: label,
        icon: AppIcons.water,
        onPressed: () async {
          await ref.read(waterViewModelProvider.notifier).registerWater(amount);
          if (!context.mounted) return;
          HBSnackBar.success(
            context,
            message: AppWaterFormatter.registered(amount),
          );
          context.pop(true);
        },
      ),
    );
  }
}
