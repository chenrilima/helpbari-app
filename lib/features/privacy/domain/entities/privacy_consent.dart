class PrivacyConsent {
  const PrivacyConsent({
    required this.id,
    required this.userId,
    required this.termsVersion,
    required this.privacyVersion,
    required this.acceptedAt,
    required this.deviceId,
    required this.timezone,
  });

  final String id;
  final String userId;
  final String termsVersion;
  final String privacyVersion;
  final DateTime acceptedAt;
  final String deviceId;
  final String timezone;
}
