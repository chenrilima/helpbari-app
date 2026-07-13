import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/validators/app_validators.dart';
import '../../domain/entities/entities.dart';
import '../providers/privacy_providers.dart';
import '../states/privacy_state.dart';

class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(privacyViewModelProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyViewModelProvider);
    ref.listen<PrivacyState>(privacyViewModelProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        HBSnackBar.error(context, message: next.errorMessage!);
      } else if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        HBSnackBar.success(context, message: next.successMessage!);
      }
    });

    if (state.isLoading) {
      return const HBPage(
        appBar: HBAppBar(title: 'Privacidade e Dados'),
        children: [HBLoading(message: 'Carregando privacidade...')],
      );
    }

    return HBLoadingOverlay(
      isLoading: state.isDeleting || state.isExporting,
      message: state.isDeleting
          ? 'Processando solicitação...'
          : 'Preparando exportação...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Privacidade e Dados',
          subtitle: 'Controle seus dados e consentimentos',
        ),
        children: [
          _DocumentsCard(onOpen: (document) => _showDocument(document)),
          const HBGap.lg(),
          _ConsentCard(state: state),
          const HBGap.lg(),
          const _StoredDataCard(),
          const HBGap.lg(),
          _ActionCard(
            onExport: () =>
                ref.read(privacyViewModelProvider.notifier).exportData(),
            onRequest: _confirmRemovalRequest,
            onDeleteData: () =>
                _confirmDestructive(account: false, state: state),
            onDeleteAccount: () =>
                _confirmDestructive(account: true, state: state),
          ),
          const HBGap.lg(),
          const HBCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.contact_support_outlined),
              title: HBText('Contato de privacidade/LGPD'),
              subtitle: HBText(PrivacyDocuments.supportContact),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDocument(PrivacyDocument document) => HBDialog.info(
    context,
    title: '${document.title} • v${document.version}',
    message: document.content,
  );

  Future<void> _confirmRemovalRequest() async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Solicitar remoção definitiva?',
      message:
          'A solicitação será registrada para análise. Nenhum dado será apagado automaticamente.',
      confirmLabel: 'Solicitar',
    );
    if (confirmed == true) {
      await ref
          .read(privacyViewModelProvider.notifier)
          .requestDefinitiveRemoval();
    }
  }

  Future<void> _confirmDestructive({
    required bool account,
    required PrivacyState state,
  }) async {
    final first = await HBDialog.confirm(
      context,
      title: account ? 'Excluir sua conta?' : 'Excluir todos os seus dados?',
      message:
          'Esta operação é irreversível, remove dados remotos e locais e encerra sua sessão.',
      confirmLabel: 'Continuar',
      barrierDismissible: false,
    );
    if (first != true || !mounted) return;
    final formKey = GlobalKey<_DestructiveConfirmationFormState>();
    final confirmedPassword = await HBDialog.custom<String>(
      context,
      title: 'Confirmação final',
      barrierDismissible: false,
      content: _DestructiveConfirmationForm(
        key: formKey,
        passwordRequired: state.passwordRequired,
      ),
      actions: [
        TextButton(
          onPressed: () => formKey.currentState?.cancel(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => formKey.currentState?.submit(),
          child: const Text('Excluir definitivamente'),
        ),
      ],
    );
    if (confirmedPassword == null || !mounted) return;
    final viewModel = ref.read(privacyViewModelProvider.notifier);
    if (account) {
      await viewModel.deleteAccount(password: confirmedPassword);
    } else {
      await viewModel.deleteData(password: confirmedPassword);
    }
  }
}

class _DestructiveConfirmationForm extends StatefulWidget {
  const _DestructiveConfirmationForm({
    required this.passwordRequired,
    super.key,
  });

  final bool passwordRequired;

  @override
  State<_DestructiveConfirmationForm> createState() =>
      _DestructiveConfirmationFormState();
}

class _DestructiveConfirmationFormState
    extends State<_DestructiveConfirmationForm> {
  final _formKey = GlobalKey<FormState>();
  final _phraseController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phraseController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void cancel() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  void submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HBTextField(
            controller: _phraseController,
            label: 'Digite EXCLUIR',
            inputFormatters: AppInputFormatters.text(maxLength: 7),
            textCapitalization: TextCapitalization.characters,
            textInputAction: widget.passwordRequired
                ? TextInputAction.next
                : TextInputAction.done,
            autofocus: true,
            validator: (value) => value?.trim() == 'EXCLUIR'
                ? null
                : 'Digite EXCLUIR para confirmar.',
            onFieldSubmitted: widget.passwordRequired ? null : (_) => submit(),
          ),
          if (widget.passwordRequired) ...[
            const HBGap.md(),
            HBPasswordField(
              controller: _passwordController,
              label: 'Senha atual',
              textInputAction: TextInputAction.done,
              validator: AppValidators.password,
              onFieldSubmitted: (_) => submit(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({required this.onOpen});
  final ValueChanged<PrivacyDocument> onOpen;

  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText('Documentos', style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const HBText('Política de Privacidade'),
          subtitle: const HBText('Versão ${PrivacyDocuments.privacyVersion}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOpen(PrivacyDocuments.policy),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const HBText('Termos de Uso'),
          subtitle: const HBText('Versão ${PrivacyDocuments.termsVersion}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => onOpen(PrivacyDocuments.terms),
        ),
      ],
    ),
  );
}

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({required this.state});
  final PrivacyState state;

  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          'Consentimentos aceitos',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const HBGap.sm(),
        if (state.consents.isEmpty)
          const HBText('Nenhum aceite registrado para esta conta.')
        else
          for (final consent in state.consents)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.verified_user_outlined),
              title: HBText(
                'Termos v${consent.termsVersion} • Política v${consent.privacyVersion}',
              ),
              subtitle: HBText(
                '${consent.acceptedAt.toLocal()} • ${consent.timezone}',
              ),
            ),
      ],
    ),
  );
}

class _StoredDataCard extends StatelessWidget {
  const _StoredDataCard();
  static const categories = <(String, String)>[
    (
      'Identificação e perfil',
      'Autenticação, personalização e segurança da conta.',
    ),
    (
      'Dados bariátricos e clínicos',
      'Histórico, acompanhamento e relatórios solicitados pelo usuário.',
    ),
    ('Preferências', 'Metas, unidades e funcionamento das funcionalidades.'),
    ('Agenda e adesão', 'Organização de consultas, vitaminas e medicamentos.'),
    (
      'Arquivos e anexos',
      'Fotos, exames e relatórios privados vinculados à conta.',
    ),
    (
      'Dados técnicos mínimos',
      'Sincronização, dispositivo, timezone e auditoria de consentimento.',
    ),
  ];

  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          'Dados armazenados e finalidade',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        for (final category in categories)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: HBText(category.$1),
            subtitle: HBText(category.$2),
          ),
      ],
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.onExport,
    required this.onRequest,
    required this.onDeleteData,
    required this.onDeleteAccount,
  });
  final VoidCallback onExport;
  final VoidCallback onRequest;
  final VoidCallback onDeleteData;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HBButton(
          label: 'Exportar meus dados',
          icon: Icons.download_outlined,
          onPressed: onExport,
        ),
        const HBGap.sm(),
        OutlinedButton(
          onPressed: onRequest,
          child: const Text('Solicitar remoção definitiva'),
        ),
        const HBGap.sm(),
        OutlinedButton(
          onPressed: onDeleteData,
          child: const Text('Excluir todos os meus dados'),
        ),
        const HBGap.sm(),
        TextButton(
          onPressed: onDeleteAccount,
          child: const Text('Excluir minha conta'),
        ),
      ],
    ),
  );
}
