import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ProgressMetricCard extends StatelessWidget {
  const ProgressMetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.description,
    super.key,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return HBMetricCard(
      title: title,
      value: value,
      description: description,
      icon: icon,
    );
  }
}
