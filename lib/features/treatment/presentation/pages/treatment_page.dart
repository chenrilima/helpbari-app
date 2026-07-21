import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';

class TreatmentPage extends StatelessWidget {
  const TreatmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(title: 'Tratamento'),
      children: [
        HBText(
          'O que você precisa tomar ou acompanhar',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const HBGap.lg(),
        HBCard(
          onTap: () => context.push(AppRoutes.medications),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.today_outlined),
            title: Text('Hoje'),
            subtitle: Text('Veja e registre os itens previstos para hoje.'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
        const HBGap.md(),
        HBCard(
          onTap: () => context.push(AppRoutes.vitamins),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.list_alt_outlined),
            title: Text('Itens'),
            subtitle: Text('Consulte os itens do seu tratamento.'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}
