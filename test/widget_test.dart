import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/app/app.dart';
import 'package:helpbari/core/services/service_providers.dart';
import 'package:helpbari/features/auth/presentation/pages/login_page.dart';
import 'package:helpbari/features/auth/presentation/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('leaves splash after initial unauthenticated state resolves', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding.completed.v1': true});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const HelpBariApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
  });
}
