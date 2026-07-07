enum VitaminStatus {
  pending,
  taken,
  skipped;

  String get label {
    return switch (this) {
      VitaminStatus.pending => 'Pendente',
      VitaminStatus.taken => 'Tomada',
      VitaminStatus.skipped => 'Ignorada',
    };
  }
}
