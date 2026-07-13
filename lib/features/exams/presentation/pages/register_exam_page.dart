import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/service_providers.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/formatters/app_input_formatters.dart';
import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/exam_view_model_provider.dart';
import '../../domain/entities/entities.dart';
import '../../../../core/media/media.dart';
import '../../../../shared/widgets/media/media_widgets.dart';
import '../../application/exam_attachment_service.dart';

class RegisterExamPage extends ConsumerStatefulWidget {
  const RegisterExamPage({super.key, this.exam});
  final Exam? exam;

  @override
  ConsumerState<RegisterExamPage> createState() => _RegisterExamPageState();
}

class _RegisterExamPageState extends ConsumerState<RegisterExamPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _laboratoryController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  MediaFile? _attachment;
  bool _removeAttachment = false;
  bool _saving = false;
  bool get _editing => widget.exam != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.exam?.name.value ?? '',
    );
    _laboratoryController = TextEditingController(
      text: widget.exam?.laboratory ?? '',
    );
    _notesController = TextEditingController(text: widget.exam?.notes ?? '');
    _selectedDate =
        widget.exam?.examDate.value ?? ref.read(clockServiceProvider).now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _laboratoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockServiceProvider).now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date == null) return;

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() => _saving = true);
    final vm = ref.read(examViewModelProvider.notifier);
    final success = _editing
        ? await vm.updateExam(
            widget.exam!,
            name: _nameController.text.trim(),
            examDate: _selectedDate,
            laboratory: _laboratoryController.text.trim(),
            notes: _notesController.text.trim(),
            attachment: _attachment,
            removeAttachment: _removeAttachment,
          )
        : await vm.createExam(
            name: _nameController.text.trim(),
            examDate: _selectedDate,
            laboratory: _laboratoryController.text.trim(),
            notes: _notesController.text.trim(),
            attachment: _attachment,
          );

    if (!mounted) return;

    if (!success) {
      setState(() => _saving = false);
      HBSnackBar.error(
        context,
        message:
            ref.read(examViewModelProvider).errorMessage ??
            'Não foi possível salvar o exame.',
      );
      return;
    }
    HBSnackBar.success(
      context,
      message: _editing
          ? 'Exame atualizado com sucesso.'
          : 'Exame cadastrado com sucesso.',
    );

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = AppDateFormatter.short(_selectedDate);

    return HBLoadingOverlay(
      isLoading: _saving,
      message: 'Salvando exame...',
      child: HBPage(
        appBar: HBAppBar(
          title: _editing ? 'Editar exame' : 'Cadastrar exame',
          subtitle: 'Acompanhe seus exames realizados',
        ),
        children: [
          HBCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HBTextField(
                    controller: _nameController,
                    label: 'Nome do exame',
                    hint: 'Ex: Hemograma completo',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: !_editing,
                    validator: AppValidators.examName,
                  ),

                  const HBGap.md(),
                  MediaAttachmentPicker(
                    initialFiles: _attachment == null
                        ? const []
                        : [_attachment!],
                    validationConfig: ExamAttachmentService.validationConfig,
                    onChanged: (files) =>
                        setState(() => _attachment = files.firstOrNull),
                    onError: (error) =>
                        HBSnackBar.error(context, message: error.message),
                  ),
                  if (_editing &&
                      widget.exam!.hasAttachment &&
                      _attachment == null) ...[
                    const HBGap.sm(),
                    CheckboxListTile(
                      value: _removeAttachment,
                      contentPadding: EdgeInsets.zero,
                      title: const HBText('Remover anexo atual'),
                      onChanged: (v) =>
                          setState(() => _removeAttachment = v ?? false),
                    ),
                  ],

                  const HBGap.md(),

                  HBTextField(
                    controller: _laboratoryController,
                    label: 'Laboratório',
                    textInputAction: TextInputAction.next,
                    inputFormatters: AppInputFormatters.text(maxLength: 120),
                    textCapitalization: TextCapitalization.words,
                    validator: AppValidators.optionalText,
                  ),

                  const HBGap.md(),

                  HBButton(
                    label: 'Data: $formattedDate',
                    onPressed: _saving ? null : _pickDate,
                  ),

                  const HBGap.md(),

                  HBTextField(
                    controller: _notesController,
                    label: 'Observações',
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    inputFormatters: AppInputFormatters.text(maxLength: 500),
                    textCapitalization: TextCapitalization.sentences,
                    validator: AppValidators.optionalText,
                    onFieldSubmitted: (_) => _save(),
                  ),

                  const HBGap.xl(),

                  HBButton(
                    label: _editing ? 'Salvar alterações' : 'Salvar exame',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
