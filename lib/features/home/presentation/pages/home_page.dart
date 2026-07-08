import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/home_view_model_provider.dart';
import '../widgets/appointment_overview_section.dart';
import '../widgets/exam_overview_section.dart';
import '../widgets/home_header.dart';
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
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadHome);
  }

  Future<void> _loadHome() async {
    await ref.read(homeViewModelProvider.notifier).loadHome();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeViewModelProvider);

    if (state.isLoading) {
      return const HBPage(
        children: [HBLoading(message: 'Carregando sua jornada...')],
      );
    }

    return HBPage(
      children: [
        HomeHeader(userName: state.profile?.name ?? 'Olá'),
        const ProgressBanner(
          title: 'Continue assim! 💜',
          message:
              'Cada registro ajuda você a acompanhar sua evolução e manter o foco.',
        ),
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
          onRefresh: _loadHome,
        ),
        const HBGap.xl(),
        VitaminsOverviewSection(
          pendingCount: state.pendingVitaminsCount,
          onRefresh: _loadHome,
        ),

        const HBGap.xl(),
        MedicationOverviewSection(
          pendingCount: state.pendingMedicationsCount,
          onRefresh: _loadHome,
        ),
        const HBGap.xl(),
        AppointmentOverviewSection(
          nextAppointment: state.nextAppointment,
          onRefresh: _loadHome,
        ),
        const HBGap.xl(),
        ExamOverviewSection(latestExam: state.latestExam, onRefresh: _loadHome),

        const HBGap.xl(),
        QuickActionsSection(onRefresh: _loadHome),
      ],
    );
  }
}
