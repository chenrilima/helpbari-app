import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/settings/domain/entities/entities.dart';
import 'package:helpbari/features/settings/domain/repositories/repositories.dart';
import 'package:helpbari/features/settings/domain/usecases/use_cases.dart';
import 'package:helpbari/features/settings/presentation/pages/settings_page.dart';
import 'package:helpbari/features/settings/presentation/providers/setting_use_cases_provider.dart';

void main() {
  testWidgets('keeps the water goal controller alive during dialog dismissal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsUseCasesProvider.overrideWithValue(
            SettingsUseCases(_SettingsRepository()),
          ),
        ],
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Meta diária de água'));
    await tester.pumpAndSettle();
    expect(find.text('Meta em ml'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Meta em ml'), findsNothing);
  });
}

final class _SettingsRepository implements SettingsRepository {
  AppSettings _settings = const AppSettings(id: 'settings');

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Future<void> saveSettings(AppSettings settings) async {
    _settings = settings;
  }
}
