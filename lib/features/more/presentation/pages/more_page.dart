import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      appBar: const HBAppBar(title: 'Mais'),
      children: [
        _Group(
          title: 'Acompanhamento',
          entries: [
            _Entry(
              'Consultas',
              Icons.calendar_month_outlined,
              AppRoutes.appointments,
            ),
            _Entry('Exames', Icons.biotech_outlined, AppRoutes.exams),
            _Entry(
              'Documentos',
              Icons.folder_outlined,
              AppRoutes.documentCenter,
            ),
            _Entry(
              'Relatórios',
              Icons.description_outlined,
              AppRoutes.medicalReports,
            ),
          ],
        ),
        const HBGap.lg(),
        _Group(
          title: 'Conteúdo',
          entries: [
            _Entry(
              'Academia Bariátrica',
              Icons.menu_book_outlined,
              AppRoutes.academy,
            ),
            _Entry(
              'Favoritos',
              Icons.favorite_outline,
              '${AppRoutes.academy}?favorites=true',
            ),
            _Entry(
              'Histórico de leitura',
              Icons.history,
              AppRoutes.academyHistory,
            ),
          ],
        ),
        const HBGap.lg(),
        _Group(
          title: 'Conta e preferências',
          entries: [
            _Entry('Perfil', Icons.person_outline, AppRoutes.profile),
            _Entry(
              'Configurações',
              Icons.settings_outlined,
              AppRoutes.settings,
            ),
            _Entry(
              'Notificações',
              Icons.notifications_outlined,
              AppRoutes.settings,
            ),
          ],
        ),
        const HBGap.lg(),
        _Group(
          title: 'Privacidade e dados',
          entries: [
            _Entry(
              'Consentimentos',
              Icons.fact_check_outlined,
              AppRoutes.privacy,
            ),
            _Entry(
              'Exportar dados',
              Icons.download_outlined,
              AppRoutes.privacy,
            ),
            _Entry(
              'Excluir conta',
              Icons.person_remove_outlined,
              AppRoutes.privacy,
            ),
          ],
        ),
        const HBGap.lg(),
        _Group(
          title: 'Ajuda',
          entries: [
            _Entry('BarIA', Icons.auto_awesome_outlined, AppRoutes.baria),
            _Entry(
              'Central de ajuda',
              Icons.help_outline,
              AppRoutes.academyFaq,
            ),
            _Entry('Termos', Icons.gavel_outlined, AppRoutes.privacy),
            _Entry('Sobre', Icons.info_outline, AppRoutes.privacy),
          ],
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.entries});
  final String title;
  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      HBText(title, style: Theme.of(context).textTheme.titleMedium),
      const HBGap.sm(),
      HBCard(
        child: Column(
          children: [
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(entry.icon),
                title: Text(entry.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(entry.route),
              ),
          ],
        ),
      ),
    ],
  );
}

class _Entry {
  const _Entry(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
}
