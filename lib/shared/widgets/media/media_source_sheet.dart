import 'package:flutter/material.dart';

import '../../../core/media/media.dart';
import '../../../design_system/design_system.dart';

class MediaSourceSheet extends StatelessWidget {
  const MediaSourceSheet({
    super.key,
    this.allowImages = true,
    this.allowPdf = true,
    this.allowCamera = true,
  });

  final bool allowImages;
  final bool allowPdf;
  final bool allowCamera;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (allowCamera && allowImages)
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'Câmera',
            onTap: () => Navigator.of(context).pop(MediaSource.camera),
          ),
        if (allowImages)
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'Galeria',
            onTap: () => Navigator.of(context).pop(MediaSource.gallery),
          ),
        if (allowPdf)
          _SourceTile(
            icon: Icons.picture_as_pdf_outlined,
            label: 'PDF',
            onTap: () => Navigator.of(context).pop(MediaSource.files),
          ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: HBText(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}
