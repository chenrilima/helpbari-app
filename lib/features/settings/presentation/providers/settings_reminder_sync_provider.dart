import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/service_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../appointments/presentation/providers/appointment_use_cases_provider.dart';
import '../../application/settings_reminder_sync_service.dart';

final settingsReminderSyncServiceProvider =
    Provider<SettingsReminderSyncService>((ref) {
      final userId = ref.watch(authSessionProvider)?.id ?? 'anonymous';
      return SettingsReminderSyncService(
        appointmentUseCases: ref.read(appointmentUseCasesProvider),
        appointmentReminders: ref.read(appointmentReminderServiceProvider),
        scheduler: ref.read(notificationSchedulerProvider),
        userId: userId,
      );
    });
