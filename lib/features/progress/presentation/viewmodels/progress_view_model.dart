import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/progress_use_cases_provider.dart';
import '../states/progress_state.dart';

class ProgressViewModel extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    return const ProgressState();
  }

  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true);

    final summary = await ref.read(progressUseCasesProvider).getSummary();

    state = ProgressState(summary: summary, isLoading: false);
  }
}
