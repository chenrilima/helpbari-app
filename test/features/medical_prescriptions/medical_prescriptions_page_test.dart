import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/medical_prescriptions/domain/entities/entities.dart';
import 'package:helpbari/features/medical_prescriptions/domain/repositories/repositories.dart';
import 'package:helpbari/features/medical_prescriptions/presentation/pages/medical_prescriptions_page.dart';
import 'package:helpbari/features/medical_prescriptions/presentation/providers/medical_prescription_providers.dart';

void main() {
  testWidgets('shows empty state and both creation actions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicalPrescriptionRepositoryProvider.overrideWithValue(
            const _Repository(),
          ),
        ],
        child: const MaterialApp(home: MedicalPrescriptionsPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma prescrição cadastrada'), findsOneWidget);
    expect(find.text('Cadastrar prescrição'), findsWidgets);
    expect(find.text('Importar receita ou prescrição'), findsOneWidget);
  });
}

class _Repository implements MedicalPrescriptionRepository {
  const _Repository();
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<MedicalPrescription>> getAll() async => const [];
  @override
  Future<MedicalPrescription?> getById(String id) async => null;
  @override
  Future<void> save(MedicalPrescription prescription) async {}
  @override
  Stream<List<MedicalPrescription>> watchAll() => const Stream.empty();
}
