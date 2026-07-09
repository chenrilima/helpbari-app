import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/app_validators.dart';
import '../../../../design_system/design_system.dart';
import '../providers/exam_view_model_provider.dart';

class RegisterExamPage extends ConsumerStatefulWidget {
  const RegisterExamPage({super.key});

  @override
  ConsumerState<RegisterExamPage> createState() => _RegisterExamPageState();
}

class _RegisterExamPageState extends ConsumerState<RegisterExamPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _laboratoryController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _laboratoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await ref
        .read(examViewModelProvider.notifier)
        .createExam(
          name: _nameController.text.trim(),
          examDate: _selectedDate,
          laboratory: _laboratoryController.text.trim(),
          notes: _notesController.text.trim(),
        );

    if (!mounted) return;

    HBSnackBar.success(context, message: 'Exame cadastrado com sucesso.');

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.day.toString().padLeft(2, '0')}/'
        '${_selectedDate.month.toString().padLeft(2, '0')}/'
        '${_selectedDate.year}';

    return HBPage(
      appBar: const HBAppBar(
        title: 'Cadastrar exame',
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
                  validator: AppValidators.examName,
                ),

                const HBGap.md(),

                HBTextField(
                  controller: _laboratoryController,
                  label: 'Laboratório',
                ),

                const HBGap.md(),

                HBButton(label: 'Data: $formattedDate', onPressed: _pickDate),

                const HBGap.md(),

                HBTextField(
                  controller: _notesController,
                  label: 'Observações',
                  maxLines: 4,
                ),

                const HBGap.xl(),

                HBButton(label: 'Salvar exame', onPressed: _save),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
