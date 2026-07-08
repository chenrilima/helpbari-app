import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/exam_state.dart';
import '../viewmodels/exam_view_model.dart';

final examViewModelProvider = NotifierProvider<ExamViewModel, ExamState>(
  ExamViewModel.new,
);
