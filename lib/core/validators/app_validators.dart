abstract final class AppValidators {
  static String? requiredText(
    String? value, {
    String message = 'Campo obrigatório.',
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return message;

    return null;
  }

  static String? name(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe o nome.';
    if (text.length < 2) return 'Informe um nome válido.';
    if (text.length > 120) return 'O nome está muito longo.';

    return null;
  }

  static String? profileName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe seu nome.';
    if (text.length < 3) return 'Informe um nome válido.';

    return null;
  }

  static String? height(String? value) {
    final height = int.tryParse(value?.trim() ?? '');

    if (height == null) return 'Informe sua altura em centímetros.';
    if (height < 80 || height > 250) return 'Informe uma altura válida.';

    return null;
  }

  static String? weight(String? value) {
    final weight = double.tryParse((value ?? '').trim().replaceAll(',', '.'));

    if (weight == null) return 'Informe um peso válido.';
    if (weight < 20 || weight > 500) return 'Informe um peso válido.';

    return null;
  }

  static String? optionalWeight(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    return weight(text);
  }

  static String? protein(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return null;

    final protein = int.tryParse(text);

    if (protein == null || protein < 0 || protein > 300) {
      return 'Informe uma quantidade válida.';
    }

    return null;
  }

  static String? title(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe o título.';
    if (text.length < 3) return 'Informe um título válido.';

    return null;
  }

  static String? examName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe o exame.';
    if (text.length < 2) return 'Informe um exame válido.';

    return null;
  }

  static String? medicationName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe o nome do medicamento.';
    if (text.length < 2) return 'Informe um nome válido.';

    return null;
  }

  static String? mealName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe o nome da refeição.';
    if (text.length < 2) return 'Informe um nome válido.';

    return null;
  }

  static String? vitaminName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe o nome da vitamina.';
    if (text.length < 2) return 'Informe um nome válido.';

    return null;
  }
}
