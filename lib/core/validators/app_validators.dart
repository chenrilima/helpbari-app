abstract final class AppValidators {
  static String? requiredText(
    String? value, {
    String message = 'Campo obrigatório.',
  }) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return message;

    return null;
  }

  static String? optionalText(String? value) {
    if ((value?.trim().length ?? 0) > 500) {
      return 'Use no máximo 500 caracteres.';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'Informe seu e-mail.';
    if (text.length > 254 ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').isEmpty) return 'Informe sua senha.';

    return null;
  }

  static String? newPassword(String? value) {
    final text = value ?? '';

    if (text.isEmpty) return 'Informe sua senha.';
    if (text.length < 6) return 'A senha deve ter pelo menos 6 caracteres.';

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
    if (text.length > 120) return 'O nome está muito longo.';

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

  static String? waterGoal(String? value) {
    final waterGoal = int.tryParse(value?.trim() ?? '');

    if (waterGoal == null || waterGoal < 500 || waterGoal > 6000) {
      return 'Informe uma meta entre 500 ml e 6000 ml.';
    }

    return null;
  }

  static String? waterAmount(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount < 1 || amount > 10000) {
      return 'Informe uma quantidade entre 1 e 10000 ml.';
    }
    return null;
  }

  static String? date(String? value) {
    final parts = (value ?? '').trim().split('/');
    if (parts.length != 3) return 'Informe uma data válida.';
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) {
      return 'Informe uma data válida.';
    }
    final date = DateTime(year, month, day);
    if (date.day != day || date.month != month || date.year != year) {
      return 'Informe uma data válida.';
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
