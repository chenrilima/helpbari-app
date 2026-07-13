import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpbari/features/onboarding/domain/entities/entities.dart';
import 'package:helpbari/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:helpbari/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:helpbari/features/onboarding/presentation/states/onboarding_state.dart';
import 'package:helpbari/features/onboarding/presentation/viewmodels/onboarding_view_model.dart';

void main() {
  testWidgets('requires both legal checkboxes before continuing', (
    tester,
  ) async {
    final viewModel = _FakeOnboardingViewModel(_documentsState());
    await _pump(tester, viewModel);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      find.text('Aceite os dois documentos para continuar.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(find.byType(Checkbox).last);
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(find.bySemanticsLabel(RegExp('Aceites pendentes')), findsNothing);
  });

  testWidgets('opens both current legal documents', (tester) async {
    final viewModel = _FakeOnboardingViewModel(_documentsState());
    await _pump(tester, viewModel);

    await tester.tap(find.byTooltip('Abrir Política de Privacidade'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Política de Privacidade • v'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Abrir Termos de Uso'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Termos de Uso • v'), findsOneWidget);
  });

  testWidgets('persists typed fields when app goes to background', (
    tester,
  ) async {
    final viewModel = _FakeOnboardingViewModel(_initialDataState());
    await _pump(tester, viewModel);

    await tester.enterText(find.byType(TextFormField).first, 'Ana Lima');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(viewModel.state.draft.name, 'Ana Lima');
    expect(viewModel.savedDrafts, isNotEmpty);
  });

  testWidgets('hydrates controllers when a saved draft is restored', (
    tester,
  ) async {
    final viewModel = _FakeOnboardingViewModel(_initialDataState());
    await _pump(tester, viewModel);

    await viewModel.updateDraft(
      viewModel.state.draft.copyWith(name: 'Ana restaurada'),
    );
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byType(TextFormField).first,
    );
    expect(field.controller?.text, 'Ana restaurada');
  });
}

Future<void> _pump(
  WidgetTester tester,
  _FakeOnboardingViewModel viewModel,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [onboardingViewModelProvider.overrideWith(() => viewModel)],
      child: const MaterialApp(home: OnboardingPage()),
    ),
  );
  await tester.pump();
}

OnboardingState _documentsState() => const OnboardingState(
  introductionCompleted: true,
  userCompleted: false,
  isAuthenticated: true,
  hasProfile: false,
  draft: OnboardingProfileDraft(),
  currentStep: OnboardingStep.documents,
);

OnboardingState _initialDataState() => const OnboardingState(
  introductionCompleted: true,
  userCompleted: false,
  isAuthenticated: true,
  hasProfile: false,
  draft: OnboardingProfileDraft(),
  currentStep: OnboardingStep.initialData,
);

class _FakeOnboardingViewModel extends OnboardingViewModel {
  _FakeOnboardingViewModel(this.initialState);

  final OnboardingState initialState;
  final savedDrafts = <OnboardingProfileDraft>[];

  @override
  OnboardingState build() => initialState;

  @override
  Future<void> updateDraft(OnboardingProfileDraft draft) async {
    savedDrafts.add(draft);
    state = state.copyWith(draft: draft, clearError: true);
  }

  @override
  Future<bool> next() async {
    if (!state.draft.documentsAccepted) return false;
    state = state.copyWith(currentStep: OnboardingStep.completion);
    return true;
  }

  @override
  Future<void> previous() async {}

  @override
  Future<void> skip() async {}

  @override
  Future<bool> complete() async => false;

  @override
  Future<void> refreshForSession({bool waitForRemote = true}) async {}
}
