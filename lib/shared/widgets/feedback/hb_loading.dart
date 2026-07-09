import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart' as ds;

class HBLoading extends StatelessWidget {
  const HBLoading({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return ds.HBLoading(message: message);
  }
}
