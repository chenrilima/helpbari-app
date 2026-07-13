import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

const List<String> _suggestions = [
  'Quanto falta para minha meta de água?',
  'Como foi minha semana?',
  'Esqueci vitaminas hoje?',
  'Quais registros estão pendentes?',
  'Quando é minha próxima consulta?',
];

class BariaSuggestionsSection extends StatelessWidget {
  const BariaSuggestionsSection({
    required this.onSuggestionSelected,
    super.key,
  });

  final Function(String) onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(
          'Perguntas frequentes:',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const HBGap.md(),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _suggestions
              .map(
                (suggestion) => _SuggestionChip(
                  label: suggestion,
                  onTap: () => onSuggestionSelected(suggestion),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(AppRadius.full),
            color: AppColors.surface,
          ),
          child: HBText(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
