class CreateWeightForm {
  const CreateWeightForm({
    required this.weight,
    required this.recordedAt,
    this.notes,
  });

  final double weight;
  final DateTime recordedAt;
  final String? notes;
}
