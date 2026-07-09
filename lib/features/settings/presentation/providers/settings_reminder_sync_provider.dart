import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../../medications/presentation/providers/medication_use_cases_provider.dart';
import '../../../vitamins/presentation/providers/vitamin_use_cases_provider.dart';
import '../../application/settings_reminder_sync_service.dart';

final settingsReminderSyncServiceProvider =
    Provider<SettingsReminderSyncService>(
      (ref) => SettingsReminderSyncService(
        vitaminUseCases: ref.read(vitaminUseCasesProvider),
        vitaminReminders: ref.read(vitaminReminderServiceProvider),
        medicationUseCases: ref.read(medicationUseCasesProvider),
        medicationReminders: ref.read(medicationReminderServiceProvider),
        appointmentUseCases: ref.read(appointmentUseCasesProvider),
        appointmentReminders: ref.read(appointmentReminderServiceProvider),
      ),
    );
