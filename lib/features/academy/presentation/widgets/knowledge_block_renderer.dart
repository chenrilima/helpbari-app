import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class KnowledgeBlockRenderer extends StatelessWidget {
  const KnowledgeBlockRenderer({
    required this.block,
    required this.faqById,
    super.key,
  });

  final KnowledgeBlock block;
  final Map<String, KnowledgeFaq> faqById;

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      KnowledgeBlockType.heading => _heading(context),
      KnowledgeBlockType.markdown => _markdown(context, block.content!),
      KnowledgeBlockType.list => _list(context),
      KnowledgeBlockType.checklist => _Checklist(items: block.checklistItems),
      KnowledgeBlockType.quote => _callout(
        context,
        icon: Icons.format_quote,
        color: AppColors.primary,
      ),
      KnowledgeBlockType.warning => _callout(
        context,
        icon: Icons.warning_amber_outlined,
        color: AppColors.warning,
      ),
      KnowledgeBlockType.medicalAlert => _callout(
        context,
        icon: Icons.medical_services_outlined,
        color: AppColors.danger,
      ),
      KnowledgeBlockType.faq => _faq(context),
      KnowledgeBlockType.table => _table(context),
      KnowledgeBlockType.image => _futureImage(context),
    };
  }

  Widget _heading(BuildContext context) {
    return Semantics(
      header: true,
      child: HBText(
        block.content!,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }

  Widget _markdown(BuildContext context, String content) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: Theme.of(context).textTheme.bodyLarge,
        blockquoteDecoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (block.title != null) ...[
          HBText(block.title!, style: Theme.of(context).textTheme.titleMedium),
          const HBGap.sm(),
        ],
        ...block.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HBText('•'),
                const HBGap.horizontal(AppSpacing.sm),
                Expanded(child: HBText(item)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _callout(
    BuildContext context, {
    required IconData icon,
    required Color color,
  }) {
    return HBCard(
      borderColor: color,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const HBGap.horizontal(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (block.title != null) ...[
                  HBText(
                    block.title!,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const HBGap.xs(),
                ],
                _markdown(context, block.content!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faq(BuildContext context) {
    final items = block.faqIds
        .map((id) => faqById[id])
        .whereType<KnowledgeFaq>();
    return Column(
      children: items
          .map(
            (faq) => HBCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
                title: HBText(faq.question),
                children: [_markdown(context, faq.answer)],
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _table(BuildContext context) {
    final table = block.table!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: table.headers
            .map((header) => DataColumn(label: HBText(header)))
            .toList(growable: false),
        rows: table.rows
            .map(
              (row) => DataRow(
                cells: row
                    .map((cell) => DataCell(HBText(cell)))
                    .toList(growable: false),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _futureImage(BuildContext context) {
    final image = block.image!;
    return HBCard(
      backgroundColor: AppColors.primaryLight,
      child: Column(
        children: [
          const Icon(Icons.image_outlined, size: AppSizes.iconXl),
          const HBGap.sm(),
          HBText(image.altText, textAlign: TextAlign.center),
          if (image.caption != null) ...[
            const HBGap.xs(),
            HBText(
              image.caption!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Checklist extends StatefulWidget {
  const _Checklist({required this.items});

  final List<KnowledgeChecklistItem> items;

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  late final List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = widget.items
        .map((item) => item.initiallyChecked)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(widget.items.length, (index) {
        return CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: HBText(widget.items[index].text),
          value: _checked[index],
          onChanged: (value) =>
              setState(() => _checked[index] = value ?? false),
        );
      }),
    );
  }
}
