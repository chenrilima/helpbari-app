import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../providers/weight_view_model_provider.dart';
import '../widgets/weight_tile.dart';

class WeightHistoryPage extends ConsumerStatefulWidget {
  const WeightHistoryPage({super.key});

  @override
  ConsumerState<WeightHistoryPage> createState() => _WeightHistoryPageState();
}

class _WeightHistoryPageState extends ConsumerState<WeightHistoryPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(weightViewModelProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(weightViewModelProvider);

    if (state.isLoading) {
      return const HBPage(
        children: [Center(child: CircularProgressIndicator())],
      );
    }

    if (state.records.isEmpty) {
      return const HBPage(
        children: [Center(child: HBText('Nenhum peso registrado.'))],
      );
    }

    return HBPage(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.records.length,
          separatorBuilder: (_, _) => const HBGap.md(),
          itemBuilder: (_, index) {
            return WeightTile(record: state.records[index]);
          },
        ),
      ],
    );
  }
}
