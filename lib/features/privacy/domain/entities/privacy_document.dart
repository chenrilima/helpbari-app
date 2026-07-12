enum PrivacyDocumentType { privacyPolicy, termsOfUse }

class PrivacyDocument {
  const PrivacyDocument({
    required this.type,
    required this.title,
    required this.version,
    required this.content,
  });

  final PrivacyDocumentType type;
  final String title;
  final String version;
  final String content;
}

abstract final class PrivacyDocuments {
  static const termsVersion = '1.0.0';
  static const privacyVersion = '1.0.0';
  static const supportContact = 'privacidade@helpbari.app';

  static const terms = PrivacyDocument(
    type: PrivacyDocumentType.termsOfUse,
    title: 'Termos de Uso',
    version: termsVersion,
    content:
        'O HelpBari organiza informações fornecidas pelo próprio usuário para acompanhamento da rotina bariátrica. O aplicativo não substitui orientação, diagnóstico ou atendimento profissional. O usuário é responsável pela veracidade dos registros e pode exportar ou solicitar a exclusão dos seus dados.',
  );

  static const policy = PrivacyDocument(
    type: PrivacyDocumentType.privacyPolicy,
    title: 'Política de Privacidade',
    version: privacyVersion,
    content:
        'Tratamos dados de identificação, perfil bariátrico, registros de saúde, preferências e anexos para fornecer sincronização, histórico, relatórios e lembretes. O acesso é restrito à conta autenticada. Não vendemos dados pessoais. O titular pode consultar, exportar, corrigir e solicitar exclusão pelo aplicativo ou pelo contato do encarregado.',
  );
}
