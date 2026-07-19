import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/formatters/app_date_formatter.dart';
import '../../../../core/services/service_providers.dart';
import '../../../../core/supabase/session/session_manager_provider.dart';
import '../../../../core/sync/sync.dart';
import '../../../../design_system/design_system.dart';
import '../../../document_intelligence/domain/entities/document_models.dart';
import '../../../document_intelligence/presentation/widgets/document_import_card.dart';
import '../../domain/entities/entities.dart';
import '../providers/medical_prescription_providers.dart';

class RegisterMedicalPrescriptionPage extends ConsumerStatefulWidget {
  const RegisterMedicalPrescriptionPage({
    super.key,
    this.prescription,
    this.importDocument = false,
  });
  final MedicalPrescription? prescription;
  final bool importDocument;
  @override
  ConsumerState<RegisterMedicalPrescriptionPage> createState() =>
      _RegisterMedicalPrescriptionPageState();
}

class _RegisterMedicalPrescriptionPageState
    extends ConsumerState<RegisterMedicalPrescriptionPage> {
  final _professional = TextEditingController();
  final _specialty = TextEditingController();
  final _registration = TextEditingController();
  final _notes = TextEditingController();
  late DateTime _prescribedAt;
  DateTime? _validUntil;
  late List<MedicalPrescriptionItem> _items;
  String? _sourceDocumentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = widget.prescription;
    _professional.text = current?.professionalName ?? '';
    _specialty.text = current?.professionalSpecialty ?? '';
    _registration.text = current?.professionalRegistration ?? '';
    _notes.text = current?.notes ?? '';
    _prescribedAt = current?.prescribedAt ?? DateTime.now();
    _validUntil = current?.validUntil;
    _items = [...?current?.activeItems];
    _sourceDocumentId = current?.sourceDocumentId;
  }

  @override
  void dispose() {
    _professional.dispose();
    _specialty.dispose();
    _registration.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HBLoadingOverlay(
    isLoading: _saving,
    message: 'Salvando prescrição...',
    child: HBPage(
      appBar: HBAppBar(
        title: widget.prescription == null
            ? 'Nova prescrição'
            : 'Editar prescrição',
        subtitle: 'Revise todos os dados antes de confirmar',
      ),
      children: [
        if (widget.importDocument) ...[
          DocumentImportCard(
            onProcessingConfirmed: (value) =>
                _sourceDocumentId = value.documentId,
            onConfirmed: _applyExtraction,
          ),
          const HBGap.lg(),
        ],
        HBTextField(controller: _professional, label: 'Profissional'),
        const HBGap.md(),
        HBTextField(controller: _specialty, label: 'Especialidade'),
        const HBGap.md(),
        HBTextField(controller: _registration, label: 'Registro profissional'),
        const HBGap.md(),
        HBButton(
          label: 'Data: ${AppDateFormatter.short(_prescribedAt)}',
          onPressed: _pickPrescribedAt,
        ),
        const HBGap.md(),
        HBButton(
          label: _validUntil == null
              ? 'Validade: não informada'
              : 'Validade: ${AppDateFormatter.short(_validUntil!)}',
          onPressed: _pickValidUntil,
        ),
        const HBGap.md(),
        HBTextField(controller: _notes, label: 'Observações', maxLines: 3),
        const HBGap.lg(),
        HBText(
          'Itens (${_items.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const HBGap.sm(),
        for (var index = 0; index < _items.length; index++) ...[
          _ItemCard(
            item: _items[index],
            onEdit: () => _editItem(index),
            onDelete: () => setState(() => _items.removeAt(index)),
          ),
          const HBGap.sm(),
        ],
        HBButton(label: 'Adicionar item', onPressed: () => _editItem(null)),
        const HBGap.lg(),
        HBButton(label: 'Salvar rascunho', onPressed: () => _save(false)),
        const HBGap.sm(),
        HBButton(label: 'Confirmar prescrição', onPressed: () => _save(true)),
      ],
    ),
  );

  Future<void> _editItem(int? index) async {
    final now = ref.read(clockServiceProvider).now().toUtc();
    final initialItem = index == null
        ? MedicalPrescriptionItem(
            id: ref.read(uuidServiceProvider).generate(),
            prescriptionId: widget.prescription?.id ?? '',
            userId: ref.read(currentUserIdProvider) ?? '',
            itemType: PrescriptionItemType.other,
            name: '',
            reviewStatus: PrescriptionReviewStatus.pending,
            createdAt: now,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
          )
        : _items[index];
    final result = await HBBottomSheet.show<MedicalPrescriptionItem>(
      context,
      title: index == null ? 'Adicionar item' : 'Editar item',
      child: _PrescriptionItemEditor(item: initialItem),
    );
    if (result == null) return;
    setState(() {
      if (index == null) {
        _items.add(result);
      } else {
        _items[index] = result;
      }
    });
  }

  Future<void> _save(bool confirm) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    if (_items.isEmpty) {
      HBSnackBar.error(context, message: 'Adicione ao menos um item.');
      return;
    }
    final now = ref.read(clockServiceProvider).now().toUtc();
    final existing = widget.prescription;
    final id = existing?.id ?? ref.read(uuidServiceProvider).generate();
    final items = _items
        .map(
          (item) => MedicalPrescriptionItem(
            id: item.id,
            prescriptionId: id,
            userId: userId,
            itemType: item.itemType,
            name: item.name,
            dosageValue: item.dosageValue,
            dosageUnit: item.dosageUnit,
            route: item.route,
            frequencyType: item.frequencyType,
            frequencyValue: item.frequencyValue,
            frequencyUnit: item.frequencyUnit,
            scheduleTimes: item.scheduleTimes,
            daysOfWeek: item.daysOfWeek,
            intervalDays: item.intervalDays,
            startDate: item.startDate,
            endDate: item.endDate,
            durationValue: item.durationValue,
            durationUnit: item.durationUnit,
            instructions: item.instructions,
            asNeeded: item.asNeeded,
            notes: item.notes,
            confidence: item.confidence,
            fieldConfidences: item.fieldConfidences,
            provenance: item.provenance,
            reviewStatus: confirm
                ? PrescriptionReviewStatus.confirmed
                : item.reviewStatus,
            linkedMedicationId: item.linkedMedicationId,
            linkedVitaminId: item.linkedVitaminId,
            createdAt: item.createdAt,
            updatedAt: now,
            syncStatus: SyncStatus.pendingUpdate,
          ),
        )
        .toList(growable: false);
    final prescription = MedicalPrescription(
      id: id,
      userId: userId,
      professionalName: _empty(_professional.text),
      professionalSpecialty: _empty(_specialty.text),
      professionalRegistration: _empty(_registration.text),
      prescribedAt: _prescribedAt,
      validUntil: _validUntil,
      notes: _empty(_notes.text),
      sourceDocumentId: _sourceDocumentId,
      status: confirm
          ? MedicalPrescriptionStatus.confirmed
          : MedicalPrescriptionStatus.draft,
      items: items,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      syncStatus: existing == null
          ? SyncStatus.pendingCreate
          : SyncStatus.pendingUpdate,
    );
    final duplicate = await ref
        .read(medicalPrescriptionViewModelProvider.notifier)
        .findDuplicate(prescription);
    if (!mounted) return;
    if (duplicate != null) {
      final proceed = await HBDialog.confirm(
        context,
        title: 'Possível duplicidade',
        message: 'Esta prescrição parece já estar cadastrada.',
        confirmLabel: 'Salvar mesmo assim',
      );
      if (proceed != true) return;
    }
    setState(() => _saving = true);
    final success = await ref
        .read(medicalPrescriptionViewModelProvider.notifier)
        .save(prescription, confirm: confirm);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!success) {
      HBSnackBar.error(
        context,
        message:
            ref.read(medicalPrescriptionViewModelProvider).errorMessage ??
            'Não foi possível salvar.',
      );
      return;
    }
    HBSnackBar.success(context, message: 'Prescrição salva com sucesso.');
    if (confirm) {
      context.go(
        AppRoutes.addPrescriptionToRoutinePath(id),
        extra: prescription,
      );
    } else {
      context.pop(true);
    }
  }

  void _applyExtraction(
    DetectedDocumentType type,
    List<ExtractedField> fields,
  ) {
    if (type != DetectedDocumentType.prescription) {
      HBSnackBar.error(
        context,
        message: 'O documento não foi reconhecido como prescrição.',
      );
      return;
    }
    String? field(String key) => fields
        .where((value) => value.key == key)
        .map(
          (value) =>
              value.confirmedValue ?? value.normalizedValue ?? value.rawValue,
        )
        .firstOrNull;
    _professional.text = field('professional_name') ?? _professional.text;
    _specialty.text = field('professional_specialty') ?? _specialty.text;
    _registration.text =
        field('professional_registration') ?? _registration.text;
    final extractedDate = _parseDate(field('prescribed_at'));
    final extractedValidity = _parseDate(field('valid_until'));
    final indexes =
        fields
            .where((value) => value.key.startsWith('item_'))
            .map(
              (value) => int.tryParse(value.key.split('.').first.substring(5)),
            )
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    final now = DateTime.now().toUtc();
    setState(() {
      if (extractedDate != null) _prescribedAt = extractedDate;
      if (extractedValidity != null) _validUntil = extractedValidity;
      _items = indexes
          .map((index) {
            String? itemField(String suffix) => field('item_$index.$suffix');
            final typeName = itemField('item_type') ?? 'other';
            return MedicalPrescriptionItem(
              id: ref.read(uuidServiceProvider).generate(),
              prescriptionId: widget.prescription?.id ?? '',
              userId: ref.read(currentUserIdProvider) ?? 'anonymous',
              itemType: PrescriptionItemType.values.byName(typeName),
              name: itemField('name') ?? '',
              dosageValue: double.tryParse(
                (itemField('dosage_value') ?? '').replaceAll(',', '.'),
              ),
              dosageUnit: itemField('dosage_unit'),
              frequencyType: itemField('frequency_type') == null
                  ? null
                  : PrescriptionFrequencyType.values.byName(
                      itemField('frequency_type')!,
                    ),
              frequencyValue: int.tryParse(itemField('frequency_value') ?? ''),
              scheduleTimes: fields
                  .where((value) => value.key == 'item_$index.schedule_time')
                  .map(
                    (value) =>
                        value.confirmedValue ??
                        value.normalizedValue ??
                        value.rawValue,
                  )
                  .toList(growable: false),
              durationValue: int.tryParse(itemField('duration_value') ?? ''),
              durationUnit: itemField('duration_unit'),
              instructions: itemField('instructions'),
              asNeeded: itemField('as_needed') == 'true',
              confidence: fields
                  .where((value) => value.key.startsWith('item_$index.'))
                  .map((value) => value.confidence)
                  .fold<double?>(
                    null,
                    (lowest, value) =>
                        lowest == null || value < lowest ? value : lowest,
                  ),
              provenance: const {'source': 'ocr'},
              reviewStatus: PrescriptionReviewStatus.pending,
              createdAt: now,
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate,
            );
          })
          .toList(growable: false);
    });
  }

  String? _empty(String value) => value.trim().isEmpty ? null : value.trim();

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    final match = RegExp(
      r'(\d{1,2})[/.\-](\d{1,2})[/.\-](\d{2,4})',
    ).firstMatch(value);
    if (match == null) return null;
    final rawYear = int.parse(match.group(3)!);
    return DateTime(
      rawYear < 100 ? 2000 + rawYear : rawYear,
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  Future<void> _pickPrescribedAt() async {
    final value = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateUtils.dateOnly(_prescribedAt),
    );
    if (value != null) setState(() => _prescribedAt = value);
  }

  Future<void> _pickValidUntil() async {
    final firstDate = DateUtils.dateOnly(_prescribedAt);
    final initial = _validUntil == null || _validUntil!.isBefore(firstDate)
        ? firstDate
        : DateUtils.dateOnly(_validUntil!);
    final value = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (value != null) setState(() => _validUntil = value);
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });
  final MedicalPrescriptionItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => HBCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HBText(item.name, style: Theme.of(context).textTheme.titleSmall),
        HBText(item.itemType.name),
        if (item.dosageValue != null)
          HBText('${item.dosageValue} ${item.dosageUnit ?? ''}'),
        if (item.instructions != null) HBText(item.instructions!),
        Row(
          children: [
            Expanded(
              child: HBButton(label: 'Editar', onPressed: onEdit),
            ),
            const HBGap.sm(),
            Expanded(
              child: HBButton(label: 'Remover', onPressed: onDelete),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PrescriptionItemEditor extends StatefulWidget {
  const _PrescriptionItemEditor({required this.item});
  final MedicalPrescriptionItem item;
  @override
  State<_PrescriptionItemEditor> createState() =>
      _PrescriptionItemEditorState();
}

class _PrescriptionItemEditorState extends State<_PrescriptionItemEditor> {
  late final TextEditingController _name;
  late final TextEditingController _dose;
  late final TextEditingController _unit;
  late final TextEditingController _instructions;
  late PrescriptionItemType _type;
  bool _asNeeded = false;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item.name);
    _dose = TextEditingController(text: item.dosageValue?.toString() ?? '');
    _unit = TextEditingController(text: item.dosageUnit ?? '');
    _instructions = TextEditingController(text: item.instructions ?? '');
    _type = item.itemType;
    _asNeeded = item.asNeeded;
  }

  @override
  void dispose() {
    _name.dispose();
    _dose.dispose();
    _unit.dispose();
    _instructions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HBTextField(controller: _name, label: 'Nome'),
        const HBGap.sm(),
        DropdownButtonFormField<PrescriptionItemType>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Tipo'),
          items: PrescriptionItemType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _type = value ?? _type),
        ),
        const HBGap.sm(),
        HBTextField(controller: _dose, label: 'Dose'),
        const HBGap.sm(),
        HBTextField(controller: _unit, label: 'Unidade'),
        const HBGap.sm(),
        HBTextField(
          controller: _instructions,
          label: 'Frequência e instruções',
          maxLines: 2,
        ),
        CheckboxListTile(
          value: _asNeeded,
          title: const Text('Se necessário'),
          onChanged: (value) => setState(() => _asNeeded = value ?? false),
        ),
        HBButton(label: 'Confirmar item', onPressed: _submit),
      ],
    ),
  );
  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final now = DateTime.now().toUtc();
    final old = widget.item;
    Navigator.of(context).pop(
      MedicalPrescriptionItem(
        id: old.id,
        prescriptionId: old.prescriptionId,
        userId: old.userId,
        itemType: _type,
        name: _name.text.trim(),
        dosageValue: double.tryParse(_dose.text.replaceAll(',', '.')),
        dosageUnit: _unit.text.trim().isEmpty ? null : _unit.text.trim(),
        instructions: _instructions.text.trim().isEmpty
            ? null
            : _instructions.text.trim(),
        asNeeded: _asNeeded,
        reviewStatus: PrescriptionReviewStatus.reviewed,
        createdAt: old.createdAt,
        updatedAt: now,
        syncStatus: old.syncStatus,
      ),
    );
  }
}
