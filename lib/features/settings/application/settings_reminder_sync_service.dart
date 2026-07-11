import '../../appointments/application/appointment_reminder_service.dart';
import '../../appointments/domain/usecases/use_cases.dart';
import '../../medications/application/medication_reminder_service.dart';
import '../../medications/domain/usecases/use_cases.dart';
import '../../vitamins/application/vitamin_reminder_service.dart';
import '../../vitamins/domain/usecases/vitamin_use_cases.dart';
import '../domain/entities/entities.dart';

class SettingsReminderSyncService {
  SettingsReminderSyncService({
    required VitaminUseCases vitaminUseCases,
    required VitaminReminderService vitaminReminders,
    required MedicationUseCases medicationUseCases,
    required MedicationReminderService medicationReminders,
    required AppointmentUseCases appointmentUseCases,
    required AppointmentReminderService appointmentReminders,
  }) : _vitaminUseCases = vitaminUseCases,
       _vitaminReminders = vitaminReminders,
       _medicationUseCases = medicationUseCases,
       _medicationReminders = medicationReminders,
       _appointmentUseCases = appointmentUseCases,
       _appointmentReminders = appointmentReminders;

  final VitaminUseCases _vitaminUseCases;
  final VitaminReminderService _vitaminReminders;
  final MedicationUseCases _medicationUseCases;
  final MedicationReminderService _medicationReminders;
  final AppointmentUseCases _appointmentUseCases;
  final AppointmentReminderService _appointmentReminders;
  String? _lastAppliedFingerprint;

  Future<bool> applyAfterCommit(AppSettings settings) async {
    final fingerprint = [
      settings.vitaminRemindersEnabled,
      settings.medicationRemindersEnabled,
      settings.appointmentRemindersEnabled,
    ].join(':');
    if (_lastAppliedFingerprint == fingerprint) return false;
    await syncVitaminReminders(settings.vitaminRemindersEnabled);
    await syncMedicationReminders(settings.medicationRemindersEnabled);
    await syncAppointmentReminders(settings.appointmentRemindersEnabled);
    _lastAppliedFingerprint = fingerprint;
    return true;
  }

  Future<void> syncVitaminReminders(bool enabled) async {
    final vitamins = await _vitaminUseCases.getAll();

    for (final vitamin in vitamins) {
      if (enabled) {
        await _vitaminReminders.rescheduleIfEnabled(vitamin);
      } else {
        await _vitaminReminders.cancel(vitamin.id);
      }
    }
  }

  Future<void> syncMedicationReminders(bool enabled) async {
    final medications = await _medicationUseCases.getAll();

    for (final medication in medications) {
      if (enabled) {
        await _medicationReminders.rescheduleIfEnabled(medication);
      } else {
        await _medicationReminders.cancel(medication.id);
      }
    }
  }

  Future<void> syncAppointmentReminders(bool enabled) async {
    final appointments = await _appointmentUseCases.getAll();

    for (final appointment in appointments) {
      if (enabled) {
        await _appointmentReminders.rescheduleIfEnabled(appointment);
      } else {
        await _appointmentReminders.cancel(appointment.id);
      }
    }
  }
}
