import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/services/service_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';
import '../../domain/value_objects/value_objects.dart';
import '../providers/meal_view_model_provider.dart';
import '../widgets/meal_summary_card.dart';
import '../widgets/meal_tile.dart';

class MealsPage extends ConsumerStatefulWidget {
  const MealsPage({super.key});

  @override
  ConsumerState<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends ConsumerState<MealsPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(_loadMeals);
  }

  Future<void> _loadMeals() async {
    await ref.read(mealViewModelProvider.notifier).loadMeals();
  }

  Future<void> _editMeal(Meal meal) async {
    final changed = await context.push<bool>(
      AppRoutes.registerMeal,
      extra: meal,
    );
    if (changed == true) {
      await _loadMeals();
    }
  }

  Future<void> _deleteMeal(String id) async {
    final confirmed = await HBDialog.confirm(
      context,
      title: 'Excluir refeição?',
      message:
          'A refeição será removida e sincronizada quando houver internet.',
      confirmLabel: 'Excluir',
    );
    if (confirmed != true || !mounted) return;
    final success = await ref
        .read(mealViewModelProvider.notifier)
        .deleteMeal(id);
    if (!mounted) return;
    if (success) {
      HBSnackBar.success(context, message: 'Refeição excluída com sucesso.');
    } else {
      HBSnackBar.error(
        context,
        message:
            ref.read(mealViewModelProvider).errorMessage ??
            'Não foi possível excluir a refeição.',
      );
    }
  }

  Future<void> _selectFilterDate() async {
    final now = ref.read(clockServiceProvider).now();
    final current = ref.read(mealViewModelProvider).dateFilter ?? now;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (selected != null) {
      ref.read(mealViewModelProvider.notifier).setDateFilter(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealViewModelProvider);

    final filteredMeals = state.filteredMeals;
    return HBLoadingOverlay(
      isLoading: state.isLoading,
      message: 'Atualizando refeições...',
      child: HBPage(
        appBar: const HBAppBar(
          title: 'Refeições',
          subtitle: 'Acompanhe sua alimentação',
        ),
        children: [
          MealSummaryCard(
            todayCount: state.todayCount,
            totalProteinToday: state.totalProteinToday,
          ),
          const HBGap.xl(),
          HBText('Histórico', style: Theme.of(context).textTheme.titleLarge),
          const HBGap.md(),
          HBCard(
            child: Column(
              children: [
                DropdownButtonFormField<MealType?>(
                  initialValue: state.typeFilter,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    const DropdownMenuItem<MealType?>(
                      value: null,
                      child: HBText('Todos'),
                    ),
                    ...MealType.values.map(
                      (type) => DropdownMenuItem<MealType?>(
                        value: type,
                        child: HBText(type.label),
                      ),
                    ),
                  ],
                  onChanged: ref
                      .read(mealViewModelProvider.notifier)
                      .setTypeFilter,
                ),
                const HBGap.md(),
                HBButton(
                  label: state.dateFilter == null
                      ? 'Filtrar por data'
                      : AppDateFormatter.short(state.dateFilter!),
                  onPressed: _selectFilterDate,
                ),
                if (state.typeFilter != null || state.dateFilter != null) ...[
                  const HBGap.sm(),
                  HBButton(
                    label: 'Limpar filtros',
                    onPressed: ref
                        .read(mealViewModelProvider.notifier)
                        .clearFilters,
                  ),
                ],
              ],
            ),
          ),
          const HBGap.md(),
          if (state.errorMessage != null)
            HBEmptyState(
              title: 'Não foi possível carregar as refeições',
              description: state.errorMessage!,
              icon: Icons.error_outline,
              actionLabel: 'Tentar novamente',
              onActionPressed: _loadMeals,
            )
          else if (!state.hasMeals)
            const HBEmptyState(
              title: 'Nenhuma refeição cadastrada',
              description: 'Cadastre sua primeira refeição.',
              icon: Icons.restaurant_outlined,
            )
          else if (filteredMeals.isEmpty)
            const HBEmptyState(
              title: 'Nenhuma refeição encontrada',
              description:
                  'Ajuste os filtros para consultar outro período ou tipo.',
              icon: Icons.filter_alt_off_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredMeals.length,
              separatorBuilder: (_, _) => const HBGap.md(),
              itemBuilder: (_, index) {
                final meal = filteredMeals[index];
                return MealTile(
                  meal: meal,
                  onEdit: () => _editMeal(meal),
                  onDelete: () => _deleteMeal(meal.id),
                );
              },
            ),
          const HBGap.xl(),
          HBButton(
            label: 'Cadastrar refeição',
            onPressed: () {
              context.pushAndRefresh(
                AppRoutes.registerMeal,
                onRefresh: _loadMeals,
                shouldRefresh: (created) => created == true,
              );
            },
          ),
        ],
      ),
    );
  }
}
