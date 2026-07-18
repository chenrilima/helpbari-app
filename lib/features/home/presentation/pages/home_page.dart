import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/health/models/daily_summary.dart';
import '../../../../design_system/design_system.dart';
import '../../../../app/bootstrap/sync_bootstrap_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/states/auth_state.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../baria/presentation/widgets/baria_home_card.dart';
import '../../../baria/presentation/providers/baria_view_model_provider.dart';
import '../providers/home_view_model_provider.dart';
import '../widgets/appointment_overview_section.dart';
import '../widgets/consultation_overview_section.dart';
import '../widgets/exam_overview_section.dart';
import '../widgets/health_score_overview_section.dart';
import '../widgets/home_header.dart';
import '../widgets/meal_overview_section.dart';
import '../widgets/medication_overview_section.dart';
import '../widgets/progress_banner.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/vitamins_overview_section.dart';
import '../widgets/water_overview_section.dart';
import '../widgets/weight_overview_section.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _disposed = Completer<void>();

  @override
  void initState() {
    super.initState();

    Future.microtask(_loadHome);
  }

  Future<void> _loadHome() async {
    final user = ref.read(authSessionProvider);
    if (user != null) {
      await ref
          .read(syncBootstrapProvider)
          .waitForInitialSync(user.id, cancelled: _disposed.future);
    }
    if (!mounted) return;
    await ref.read(homeViewModelProvider.notifier).loadHome();
  }

  @override
  void dispose() {
    if (!_disposed.isCompleted) _disposed.complete();
    super.dispose();
  }

  Future<void> _signOut() async {
    await ref.read(authViewModelProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);
    final authState = ref.watch(authViewModelProvider);
    final isSigningOut = authState is AuthLoading;

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next case AuthFailure(:final message)) {
        HBSnackBar.error(context, message: message);
      }
    });

    if (state.isLoading && state.dailySummary == null) {
      return const HBPage(
        children: [HBLoading(message: 'Carregando sua jornada...')],
      );
    }

    return HBLoadingOverlay(
      isLoading: isSigningOut,
      message: 'Saindo...',
      child: HBPage(
        appBar: HBAppBar(
          title: 'HelpBari',
          actions: [
            IconButton(
              tooltip: 'Sair',
              onPressed: isSigningOut ? null : _signOut,
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        children: [
          if (state.errorMessage != null) ...[
            HBEmptyState(
              title: 'Dashboard indisponível',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _loadHome,
            ),
            const HBGap.xl(),
          ],
          if (state.hasPartialFailure) ...[
            const HBEmptyState(
              title: 'Algumas seções estão indisponíveis',
              description:
                  'Os demais dados locais continuam disponíveis e serão atualizados na próxima sincronização.',
              icon: Icons.sync_problem_outlined,
            ),
            const HBGap.xl(),
          ],
          HomeHeader(userName: state.profile?.name ?? 'Olá'),
          ProgressBanner(
            title: state.bannerTitle,
            message: state.bannerMessage,
          ),
          if (state.dailySummary != null) ...[
            const HBGap.xl(),
            HealthScoreOverviewSection(
              healthScore: state.dailySummary!.healthScore,
            ),
            const HBGap.xl(),
            _BariaCardSection(dailySummary: state.dailySummary!),
          ],
          const HBGap.xl(),
          WeightOverviewSection(
            latestRecord: state.latestWeightRecord,
            hasRecords: state.hasWeightRecords,
            progressMessage: state.formattedWeightLost,
            onRefresh: _loadHome,
          ),
          const HBGap.xl(),
          WaterOverviewSection(
            totalTodayInMl: state.totalWaterTodayInMl,
            goalMl: state.dailySummary?.waterGoalMl ?? 2000,
            subtitle: state.waterMessage,
            onRefresh: _loadHome,
          ),
          const HBGap.xl(),
          VitaminsOverviewSection(
            pendingCount: state.pendingVitaminsCount,
            subtitle: state.vitaminsMessage,
            onRefresh: _loadHome,
          ),

          const HBGap.xl(),
          MedicationOverviewSection(
            pendingCount: state.pendingMedicationsCount,
            subtitle: state.medicationsMessage,
            onRefresh: _loadHome,
          ),
          const HBGap.xl(),
          MealOverviewSection(
            todayCount: state.todayMealsCount,
            totalProteinToday: state.totalProteinToday,
            subtitle: state.mealsMessage,
            onRefresh: _loadHome,
          ),
          const HBGap.xl(),
          AppointmentOverviewSection(
            nextAppointment: state.nextAppointment,
            subtitle: state.appointmentMessage,
            onRefresh: _loadHome,
          ),
          const HBGap.xl(),
          ConsultationOverviewSection(
            latestConsultation: state.latestConsultation,
            subtitle: state.consultationMessage,
            onRefresh: _loadHome,
          ),
          const HBGap.xl(),
          ExamOverviewSection(
            latestExam: state.latestExam,
            subtitle: state.examMessage,
            onRefresh: _loadHome,
          ),

          const HBGap.xl(),
          QuickActionsSection(onRefresh: _loadHome),
        ],
      ),
    );
  }
}

class _BariaCardSection extends ConsumerStatefulWidget {
  const _BariaCardSection({required this.dailySummary});

  final DailySummary dailySummary;

  @override
  ConsumerState<_BariaCardSection> createState() => _BariaCardSectionState();
}

class _BariaCardSectionState extends ConsumerState<_BariaCardSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadBaria);
  }

  Future<void> _loadBaria() async {
    await ref.read(bariaViewModelProvider.notifier).loadDailyInsight();
  }

  @override
  Widget build(BuildContext context) {
    final bariaState = ref.watch(bariaViewModelProvider);

    if (bariaState.dailyInsight == null) {
      return const SizedBox.shrink();
    }

    return BariaHomeCard(insight: bariaState.dailyInsight!);
  }
}
