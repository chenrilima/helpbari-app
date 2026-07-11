import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

const List<String> _suggestions = [
  'Como está minha hidratação?',
  'Como melhorar meu Health Score?',
  'O que ficou pendente hoje?',
  'Resumo da minha jornada',
  'Preparar para consulta',
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
          spacing: 8,
          runSpacing: 8,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: HBText(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.blue),
        ),
      ),
    );
  }
}
