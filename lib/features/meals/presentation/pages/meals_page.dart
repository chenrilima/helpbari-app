import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/extensions/context_navigation_extension.dart';
import '../../../../design_system/design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mealViewModelProvider);

    return HBPage(
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
        if (!state.hasMeals)
          const HBEmptyState(
            title: 'Nenhuma refeição cadastrada',
            description: 'Cadastre sua primeira refeição.',
            icon: Icons.restaurant_outlined,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.meals.length,
            separatorBuilder: (_, _) => const HBGap.md(),
            itemBuilder: (_, index) {
              return MealTile(meal: state.meals[index]);
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
    );
  }
}
