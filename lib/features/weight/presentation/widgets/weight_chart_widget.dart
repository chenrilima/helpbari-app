import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class WeightChartWidget extends StatelessWidget {
  const WeightChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const HBCard(
      child: SizedBox(
        height: 220,
        child: Center(child: HBText('Gráfico disponível em breve.')),
      ),
    );
  }
}
