enum MedicationStatus {
  pending,
  taken,
  skipped;

  String get label {
    return switch (this) {
      MedicationStatus.pending => 'Pendente',
      MedicationStatus.taken => 'Tomado',
      MedicationStatus.skipped => 'Ignorado',
    };
  }
}
