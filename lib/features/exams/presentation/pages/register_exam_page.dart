import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class RegisterExamPage extends StatelessWidget {
  const RegisterExamPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      children: [
        HBText(
          'Cadastrar Exam',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
