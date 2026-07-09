import 'package:flutter/material.dart';

import '../../../core/media/media.dart';
import '../../../design_system/design_system.dart';

class MediaPreviewTile extends StatelessWidget {
  const MediaPreviewTile({
    required this.file,
    super.key,
    this.onDelete,
    this.onTap,
  });

  final MediaFile file;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final preview = file.type.isImage
        ? Image.memory(
            file.bytes,
            fit: BoxFit.cover,
            width: 56,
            height: 56,
            gaplessPlayback: true,
          )
        : const Icon(
            Icons.picture_as_pdf_outlined,
            color: AppColors.danger,
            size: AppSizes.iconLg,
          );

    return Semantics(
      button: onTap != null,
      label: 'Arquivo selecionado: ${file.name}',
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: ColoredBox(
                      color: AppColors.background,
                      child: Center(child: preview),
                    ),
                  ),
                ),
                const HBGap.horizontal(AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HBText(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const HBGap.xs(),
                      HBText(
                        _formatSize(file.sizeInBytes),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onDelete != null) ...[
                  const HBGap.horizontal(AppSpacing.sm),
                  IconButton(
                    tooltip: 'Remover arquivo',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';

    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }
}
