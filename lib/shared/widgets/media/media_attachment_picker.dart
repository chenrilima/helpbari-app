import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/media/media.dart';
import '../../../design_system/design_system.dart';
import 'media_preview_tile.dart';
import 'media_source_sheet.dart';

class MediaAttachmentPicker extends ConsumerStatefulWidget {
  const MediaAttachmentPicker({
    required this.onChanged,
    super.key,
    this.initialFiles = const [],
    this.validationConfig = const MediaValidationConfig(),
    this.processingConfig = const MediaProcessingConfig(),
    this.label = 'Anexar arquivo',
    this.emptyLabel = 'Selecionar imagem ou PDF',
    this.onError,
  });

  final List<MediaFile> initialFiles;
  final ValueChanged<List<MediaFile>> onChanged;
  final MediaValidationConfig validationConfig;
  final MediaProcessingConfig processingConfig;
  final String label;
  final String emptyLabel;
  final ValueChanged<AppException>? onError;

  @override
  ConsumerState<MediaAttachmentPicker> createState() =>
      _MediaAttachmentPickerState();
}

class _MediaAttachmentPickerState extends ConsumerState<MediaAttachmentPicker> {
  late List<MediaFile> _files;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _files = List.of(widget.initialFiles);
  }

  @override
  void didUpdateWidget(covariant MediaAttachmentPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFiles != widget.initialFiles) {
      _files = List.of(widget.initialFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _files.length < widget.validationConfig.maxFiles;
    final allowImages = widget.validationConfig.allowedTypes.contains(
      MediaFileType.image,
    );
    final allowPdf = widget.validationConfig.allowedTypes.contains(
      MediaFileType.pdf,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HBText(
          widget.label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const HBGap.sm(),
        for (final file in _files) ...[
          MediaPreviewTile(file: file, onDelete: () => _remove(file)),
          const HBGap.sm(),
        ],
        if (canAdd)
          OutlinedButton.icon(
            onPressed: _isLoading || (!allowImages && !allowPdf)
                ? null
                : () => _selectMedia(
                    allowImages: allowImages,
                    allowPdf: allowPdf,
                  ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file_outlined),
            label: Text(widget.emptyLabel),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectMedia({
    required bool allowImages,
    required bool allowPdf,
  }) async {
    final source = await HBBottomSheet.show<MediaSource>(
      context,
      title: widget.emptyLabel,
      child: MediaSourceSheet(allowImages: allowImages, allowPdf: allowPdf),
    );

    if (source == null) return;

    setState(() => _isLoading = true);

    try {
      final picker = ref.read(mediaPickerServiceProvider);
      final selected = switch (source) {
        MediaSource.camera || MediaSource.gallery => await picker.pickImage(
          source: source,
          processingConfig: widget.processingConfig,
        ),
        MediaSource.files => await picker.pickPdf(
          processingConfig: widget.processingConfig,
        ),
      };

      if (selected == null) return;

      final nextFiles = [..._files, selected];
      final validation = ref
          .read(mediaValidationServiceProvider)
          .validateFiles(nextFiles, config: widget.validationConfig);

      if (validation != null) {
        widget.onError?.call(validation);
        return;
      }

      setState(() => _files = nextFiles);
      widget.onChanged(List.unmodifiable(_files));
    } catch (error, stackTrace) {
      final exception = mapMediaException(error, stackTrace);
      widget.onError?.call(exception);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _remove(MediaFile file) async {
    setState(() {
      _files = _files.where((item) => item.id != file.id).toList();
    });

    await ref.read(mediaCacheServiceProvider).remove(file);
    widget.onChanged(List.unmodifiable(_files));
  }
}
