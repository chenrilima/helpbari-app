import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class KnowledgeArticleCard extends StatelessWidget {
  const KnowledgeArticleCard({
    required this.article,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoritePressed,
    super.key,
    this.progress,
  });

  final KnowledgeArticle article;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;
  final KnowledgeProgress? progress;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      onTap: onTap,
      semanticLabel: '${article.title}, ${article.readingTimeMinutes} minutos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: HBText(
                  article.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: isFavorite
                    ? 'Remover dos favoritos'
                    : 'Adicionar aos favoritos',
                onPressed: onFavoritePressed,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? AppColors.danger
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          HBText(
            article.summary,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const HBGap.md(),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _Metadata(
                icon: Icons.schedule,
                label: '${article.readingTimeMinutes} min',
              ),
              _Metadata(
                icon: Icons.science_outlined,
                label: _evidenceLabel(article.evidenceLevel),
              ),
            ],
          ),
          if (progress != null) ...[
            const HBGap.md(),
            LinearProgressIndicator(
              value: progress!.completedPercent,
              semanticsLabel: 'Progresso da leitura',
              semanticsValue: '${(progress!.completedPercent * 100).round()}%',
            ),
          ],
        ],
      ),
    );
  }

  static String _evidenceLabel(KnowledgeEvidenceLevel level) {
    return switch (level) {
      KnowledgeEvidenceLevel.consensus => 'Consenso',
      KnowledgeEvidenceLevel.low => 'Evidência baixa',
      KnowledgeEvidenceLevel.moderate => 'Evidência moderada',
      KnowledgeEvidenceLevel.high => 'Evidência alta',
    };
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconXs, color: AppColors.textSecondary),
        const HBGap.horizontal(AppSpacing.xs),
        HBText(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
