import '../../../../core/supabase/database/supabase_database.dart';
import '../dtos/medical_prescription_dto.dart';

class MedicalPrescriptionSupabaseDatasource {
  const MedicalPrescriptionSupabaseDatasource(this._database);

  final SupabaseDatabase _database;
  static const prescriptionTable = 'medical_prescriptions';
  static const itemTable = 'medical_prescription_items';

  Future<MedicalPrescriptionDto> upsert(
    MedicalPrescriptionDto dto, {
    required String userId,
  }) async {
    if (dto.prescription.userId != userId) {
      throw StateError('Prescription user mismatch.');
    }
    await _database.run(
      operation: 'upsert',
      table: prescriptionTable,
      request: (query) => query.upsert(dto.toSupabasePrescriptionRow()),
    );
    final items = dto.toSupabaseItemRows();
    if (items.isNotEmpty) {
      await _database.run(
        operation: 'upsert',
        table: itemTable,
        request: (query) => query.upsert(items),
      );
    }
    return dto;
  }

  Future<List<MedicalPrescriptionDto>> pull({
    required String userId,
    DateTime? updatedAfter,
  }) => _database.run(
    operation: 'select',
    table: prescriptionTable,
    request: (query) async {
      var request = query.select().eq('user_id', userId);
      if (updatedAfter != null) {
        request = request.gt(
          'updated_at',
          updatedAfter.toUtc().toIso8601String(),
        );
      }
      final rows = await request.order('updated_at');
      final result = <MedicalPrescriptionDto>[];
      for (final row in rows) {
        final id = row['id'] as String;
        final itemRows = await _database.run(
          operation: 'select',
          table: itemTable,
          request: (inner) =>
              inner.select().eq('user_id', userId).eq('prescription_id', id),
        );
        result.add(
          MedicalPrescriptionDto.fromSupabaseRows(
            prescription: Map<String, dynamic>.from(row),
            items: itemRows
                .map((item) => Map<String, dynamic>.from(item))
                .toList(growable: false),
          ),
        );
      }
      return result;
    },
  );
}
