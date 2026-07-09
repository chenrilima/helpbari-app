import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/services/services.dart';
import '../../../settings/presentation/providers/setting_use_cases_provider.dart';
import '../../domain/entities/entities.dart';
import '../../domain/usecases/use_cases.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/medication_use_cases_provider.dart';
import '../states/medication_state.dart';

class MedicationViewModel extends Notifier<MedicationState> {
  late final MedicationUseCases _useCases;
  late final UuidService _uuidService;
  late final LoggerService _logger;
  late final LocalNotificationService _notifications;

  @override
  MedicationState build() {
    _useCases = ref.read(medicationUseCasesProvider);
    _logger = ref.read(loggerServiceProvider);
    _uuidService = ref.read(uuidServiceProvider);
    _notifications = ref.read(localNotificationServiceProvider);
    return const MedicationState();
  }

  Future<void> loadMedications() async {
    state = state.copyWith(isLoading: true);

    final medications = await _useCases.getAll();

    state = state.copyWith(medications: medications, isLoading: false);
  }

  Future<void> createMedication({
    required String name,
    required int hour,
    required int minute,
    String? dosage,
    String? notes,
  }) async {
    final medicationName = MedicationName.create(name);
    final scheduleTime = MedicationScheduleTime.create(
      hour: hour,
      minute: minute,
    );

    if (medicationName == null || scheduleTime == null) {
      return;
    }

    final medication = Medication(
      id: _uuidService.generate(),
      name: medicationName,
      scheduleTime: scheduleTime,
      dosage: dosage,
      notes: notes,
    );

    await _useCases.save(medication);
    await _scheduleReminderIfEnabled(medication);
    await loadMedications();
    _logger.info('Medicamento cadastrado.');
  }

  Future<void> markAsTaken(String id) async {
    await _useCases.markAsTaken(id);
    await loadMedications();
  }

  Future<void> markAsSkipped(String id) async {
    await _useCases.markAsSkipped(id);
    await loadMedications();
  }

  Future<void> resetStatus(String id) async {
    await _useCases.resetStatus(id);
    await loadMedications();
  }

  Future<void> _scheduleReminderIfEnabled(Medication medication) async {
    final settings = await ref.read(settingsUseCasesProvider).getSettings();

    if (!settings.medicationRemindersEnabled) return;

    await _notifications.scheduleRecurring(
      NotificationSchedules.medication(medication),
    );
  }
}
