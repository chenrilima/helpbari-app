enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label {
    return switch (this) {
      MealType.breakfast => 'Café da manhã',
      MealType.lunch => 'Almoço',
      MealType.dinner => 'Jantar',
      MealType.snack => 'Lanche',
    };
  }
}
