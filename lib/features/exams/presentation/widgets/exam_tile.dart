import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class ExamTile extends StatelessWidget {
  const ExamTile({required this.item, super.key});

  final Exam item;

  @override
  Widget build(BuildContext context) {
    return HBCard(child: HBText(item.title));
  }
}
