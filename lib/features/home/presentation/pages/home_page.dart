import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/bootstrap/sync_bootstrap_provider.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/states/auth_state.dart';
import '../../../auth/presentation/viewmodels/auth_providers.dart';
import '../../../smart_routines/application/notification_platform.dart';
import '../../../smart_routines/presentation/providers/unified_treatment_providers.dart';
import '../../domain/models/home_intelligence_models.dart';
import '../../application/home_runtime_guard.dart';
import '../providers/home_view_model_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/home_intelligence_sections.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with WidgetsBindingObserver {
  final _disposed = Completer<void>();
  final _runtimeGuard = HomeRuntimeGuard();
  static const _dayPolicy = ClinicalDayRefreshPolicy();
  Timer? _dayRefreshTimer;
  DateTime? _snapshotDate;
  String? _snapshotTimeZone;
  bool _dashboardReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_refreshAfterSync);
    Future.microtask(_scheduleDayRefresh);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _dashboardReady = true);
    });
  }

  Future<void> _refreshAfterSync() async {
    final user = ref.read(authSessionProvider);
    if (user == null) return;
    await ref
        .read(syncBootstrapProvider)
        .waitForInitialSync(user.id, cancelled: _disposed.future);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dayRefreshTimer?.cancel();
    if (!_disposed.isCompleted) _disposed.complete();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshForClinicalDayIfNeeded();
    }
  }

  void _scheduleDayRefresh() {
    _dayRefreshTimer?.cancel();
    final now = ref.read(clockServiceProvider).now();
    _dayRefreshTimer = Timer(_dayPolicy.untilNextDay(now), () {
      if (!mounted) return;
      ref.invalidate(homeClinicalNowProvider);
      _scheduleDayRefresh();
    });
  }

  void _refreshForClinicalDayIfNeeded() {
    final snapshotDate = _snapshotDate;
    final snapshotTimeZone = _snapshotTimeZone;
    if (snapshotDate == null || snapshotTimeZone == null) return;
    final currentTimeZone =
        ref.read(notificationSchedulerProvider).state.timeZone ?? 'UTC';
    if (_dayPolicy.shouldRefresh(
      snapshotDate: snapshotDate,
      now: ref.read(clockServiceProvider).now(),
      snapshotTimeZone: snapshotTimeZone,
      currentTimeZone: currentTimeZone,
    )) {
      ref.invalidate(homeClinicalNowProvider);
      _scheduleDayRefresh();
    }
  }

  Future<void> _retry() async {
    ref.invalidate(todayDashboardProvider);
    await ref.read(todayDashboardProvider.future);
  }

  Future<void> _openRoute(String? route) async {
    if (route == null || route == AppRoutes.home) return;
    await context.push(route);
  }

  Future<void> _openFeature(String route) async {
    if (route == AppRoutes.home || !mounted) return;
    await context.push(route);
  }

  Future<void> _runNextAction(NextActionReadModel action) async {
    if (action.command != HomeActionKind.treatmentCommand) {
      return _openRoute(action.deepLink);
    }
    final prefix = 'next:treatment:';
    if (!action.id.startsWith(prefix)) return;
    await _recordOccurrence(action.id.substring(prefix.length));
  }

  Future<void> _runAgendaItem(AgendaItemReadModel item) async {
    if (item.allowedActions.contains(HomeActionKind.treatmentCommand)) {
      await _recordOccurrence(item.sourceId);
      return;
    }
    await _openRoute(item.deepLink);
  }

  Future<void> _recordOccurrence(String occurrenceId) async {
    final guardKey = 'occurrence:$occurrenceId';
    if (!_runtimeGuard.begin(guardKey)) return;
    final expectedUserId = ref.read(authSessionProvider)?.id;
    if (expectedUserId == null) {
      _runtimeGuard.complete(guardKey);
      return;
    }
    try {
      final action = await HBDialog.custom<RoutineNotificationActionType>(
        context,
        title: 'Registrar rotina',
        content: const HBText(
          'Escolha apenas o que corresponde ao seu registro. Esta ação não altera dose ou tratamento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, RoutineNotificationActionType.skipped),
            child: const Text('Não realizado'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, RoutineNotificationActionType.taken),
            child: const Text('Registrar conclusão'),
          ),
        ],
      );
      if (action == null ||
          !mounted ||
          ref.read(authSessionProvider)?.id != expectedUserId) {
        return;
      }
      final user = ref.read(authSessionProvider);
      if (user == null || user.id != expectedUserId) return;
      try {
        final commands = await ref.read(
          notificationPlatformRepositoryProvider.future,
        );
        await commands.markOccurrence(
          userId: user.id,
          occurrenceId: occurrenceId,
          actionId: ref.read(uuidServiceProvider).generate(),
          action: action,
          occurredAtUtc: ref.read(clockServiceProvider).now().toUtc(),
        );
        ref.invalidate(todayDashboardProvider);
        if (mounted) {
          HBSnackBar.success(context, message: 'Registro salvo no aparelho.');
        }
      } catch (_) {
        if (mounted) {
          HBSnackBar.error(
            context,
            message: 'Não foi possível salvar este registro.',
          );
        }
      }
    } finally {
      _runtimeGuard.complete(guardKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next case AuthFailure(:final message)) {
        HBSnackBar.error(context, message: message);
      }
    });

    if (!_dashboardReady) {
      return const HBPage(
        children: [HBLoading(message: 'Carregando dados do aparelho...')],
      );
    }

    final dashboard = ref.watch(todayDashboardProvider);

    return HBLoadingOverlay(
      isLoading: authState is AuthLoading,
      message: 'Saindo...',
      child: dashboard.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        loading: () => const HBPage(
          children: [HBLoading(message: 'Carregando dados do aparelho...')],
        ),
        error: (error, stackTrace) => HBPage(
          appBar: _appBar(false),
          children: [
            HBEmptyState(
              title: 'Home indisponível',
              description:
                  'Não foi possível carregar os dados locais neste momento.',
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _retry,
            ),
          ],
        ),
        data: (model) {
          _snapshotDate = model.clinicalDate;
          _snapshotTimeZone = model.timeZone;
          return _content(model, authState is AuthLoading);
        },
      ),
    );
  }

  PreferredSizeWidget _appBar(bool isSigningOut) => HBAppBar(
    title: 'Hoje',
    actions: [
      IconButton(
        tooltip: 'Abrir perfil',
        onPressed: isSigningOut ? null : () => _openRoute(AppRoutes.profile),
        icon: const Icon(Icons.account_circle_outlined),
      ),
    ],
  );

  Widget _content(TodayDashboardReadModel model, bool isSigningOut) {
    return HBScaffold(
      appBar: _appBar(isSigningOut),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeHeader(userName: model.userName ?? 'Olá'),
          const HBGap.lg(),
          HomeFreshnessBanner(status: model.status),
          if (model.status.freshness.isStale || model.status.hasPendingSync)
            const HBGap.lg(),
          _NextActionsConsumer(onAction: _runNextAction),
          const HBGap.xl(),
          _AgendaConsumer(onItem: _runAgendaItem),
          const HBGap.xl(),
          _ProgressConsumer(),
          const HBGap.xl(),
          _InsightsConsumer(onOpen: (value) => _openRoute(value.deepLink)),
          const HBGap.xl(),
          _QuickActionsConsumer(
            onAction: (action) {
              if (action.kind == HomeActionKind.treatmentCommand &&
                  action.sourceId != null) {
                _recordOccurrence(action.sourceId!);
              } else {
                _openFeature(action.deepLink ?? AppRoutes.home);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _NextActionsConsumer extends ConsumerWidget {
  const _NextActionsConsumer({required this.onAction});
  final ValueChanged<NextActionReadModel> onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(nextActionsProvider)
      .when(
        data: (value) => NextActionsSection(model: value, onAction: onAction),
        loading: () => const HBLoading(message: 'Carregando próximas ações...'),
        error: (_, _) => const HBEmptyState(
          title: 'Próximas ações indisponíveis',
          description: 'Os demais dados locais continuam disponíveis.',
        ),
      );
}

class _AgendaConsumer extends ConsumerWidget {
  const _AgendaConsumer({required this.onItem});
  final ValueChanged<AgendaItemReadModel> onItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(todayAgendaProvider)
      .when(
        data: (value) => IntelligentAgendaSection(model: value, onItem: onItem),
        loading: () => const HBLoading(message: 'Carregando agenda local...'),
        error: (_, _) => const HBEmptyState(
          title: 'Agenda indisponível',
          description: 'Tente atualizar somente esta seção.',
        ),
      );
}

class _QuickActionsConsumer extends ConsumerWidget {
  const _QuickActionsConsumer({required this.onAction});
  final ValueChanged<QuickActionReadModel> onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(quickActionsProvider)
      .when(
        data: (value) =>
            IntelligentQuickActionsSection(model: value, onAction: onAction),
        loading: () => const HBLoading(message: 'Carregando ações...'),
        error: (_, _) => const SizedBox.shrink(),
      );
}

class _ProgressConsumer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(dailyProgressProvider)
      .when(
        data: (value) => DailyProgressSection(model: value),
        loading: () =>
            const HBLoading(message: 'Carregando progresso local...'),
        error: (_, _) => const HBEmptyState(
          title: 'Progresso indisponível',
          description: 'A agenda permanece disponível.',
        ),
      );
}

class _InsightsConsumer extends ConsumerWidget {
  const _InsightsConsumer({required this.onOpen});
  final ValueChanged<DeterministicInsightReadModel> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(homeInsightsProvider)
      .when(
        data: (value) => HomeInsightSection(model: value, onOpen: onOpen),
        loading: () => const HBLoading(message: 'Analisando dados locais...'),
        error: (_, _) => const SizedBox.shrink(),
      );
}
