import '../../../../core/domain/entity.dart';
import '../../../../core/formatters/app_protein_formatter.dart';
import '../value_objects/value_objects.dart';

class Meal extends Entity {
  const Meal({
    required this.id,
    required this.name,
    required this.type,
    required this.mealDate,
    this.notes,
    this.proteinGrams,
  });

  @override
  final String id;

  final MealName name;
  final MealType type;
  final MealDate mealDate;
  final String? notes;
  final int? proteinGrams;

  String get formattedName => name.value;

  String get formattedDate => mealDate.formatted;

  String get formattedType => type.label;

  bool get wasRegisteredToday => mealDate.isToday;

  bool get hasProteinInfo => proteinGrams != null && proteinGrams! > 0;

  String get formattedProtein {
    if (!hasProteinInfo) {
      return 'Proteína não informada';
    }

    return AppProteinFormatter.meal(proteinGrams!);
  }

  Meal copyWith({
    MealName? name,
    MealType? type,
    MealDate? mealDate,
    String? notes,
    int? proteinGrams,
  }) {
    return Meal(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      mealDate: mealDate ?? this.mealDate,
      notes: notes ?? this.notes,
      proteinGrams: proteinGrams ?? this.proteinGrams,
    );
  }
}
