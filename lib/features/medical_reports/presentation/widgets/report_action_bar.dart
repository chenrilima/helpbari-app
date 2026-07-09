import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ReportActionBar extends StatelessWidget {
  const ReportActionBar({
    required this.onGenerate,
    required this.onDownload,
    required this.onShare,
    required this.onPrint,
    required this.isGenerating,
    required this.isDownloading,
    required this.isSharing,
    required this.isPrinting,
    super.key,
  });

  final VoidCallback? onGenerate;
  final VoidCallback? onDownload;
  final VoidCallback? onShare;
  final VoidCallback? onPrint;
  final bool isGenerating;
  final bool isDownloading;
  final bool isSharing;
  final bool isPrinting;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HBButton(
          label: 'Gerar PDF',
          icon: Icons.picture_as_pdf_outlined,
          isLoading: isGenerating,
          onPressed: onGenerate,
        ),
        const HBGap.md(),
        Row(
          children: [
            Expanded(
              child: HBButton(
                label: 'Baixar',
                icon: Icons.download_outlined,
                isLoading: isDownloading,
                onPressed: onDownload,
              ),
            ),
            const HBGap.horizontal(AppSpacing.md),
            Expanded(
              child: HBButton(
                label: 'Compartilhar',
                icon: Icons.ios_share_outlined,
                isLoading: isSharing,
                onPressed: onShare,
              ),
            ),
          ],
        ),
        const HBGap.md(),
        HBButton(
          label: 'Imprimir',
          icon: Icons.print_outlined,
          isLoading: isPrinting,
          onPressed: onPrint,
        ),
      ],
    );
  }
}
