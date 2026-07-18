import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class AppointmentTile extends StatelessWidget {
  const AppointmentTile({
    required this.appointment,
    required this.onComplete,
    required this.onCancel,
    required this.onRegisterConsultation,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Appointment appointment;
  final VoidCallback onComplete;
  final VoidCallback onCancel;
  final VoidCallback onRegisterConsultation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const ExcludeSemantics(
            child: Icon(AppIcons.calendar, color: AppColors.primary),
          ),

          const HBGap.md(),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HBText(
                  appointment.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const HBGap.xs(),

                HBText(
                  appointment.formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                if (appointment.doctorName != null) ...[
                  const HBGap.xs(),
                  HBText(
                    appointment.doctorName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          if (appointment.isScheduled) ...[
            IconButton(
              tooltip: 'Registrar consulta',
              onPressed: onRegisterConsultation,
              icon: const Icon(Icons.note_add_outlined),
            ),
            IconButton(
              tooltip: 'Cancelar consulta',
              onPressed: onCancel,
              icon: const Icon(Icons.close),
            ),
            IconButton(
              tooltip: 'Concluir consulta',
              onPressed: onComplete,
              icon: const Icon(Icons.check),
            ),
          ],
          IconButton(
            tooltip: 'Editar consulta',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir consulta',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
    );
  }
}
