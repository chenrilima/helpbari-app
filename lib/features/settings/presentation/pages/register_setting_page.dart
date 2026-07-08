import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class RegisterSettingPage extends StatelessWidget {
  const RegisterSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return HBPage(
      children: [
        HBText(
          'Cadastrar Setting',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ],
    );
  }
}
