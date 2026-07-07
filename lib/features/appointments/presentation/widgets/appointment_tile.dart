import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../domain/entities/entities.dart';

class AppointmentTile extends StatelessWidget {
  const AppointmentTile({
    required this.appointment,
    required this.onComplete,
    required this.onCancel,
    super.key,
  });

  final Appointment appointment;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return HBCard(
      child: Row(
        children: [
          const Icon(AppIcons.calendar, color: AppColors.primary),

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
            IconButton(onPressed: onCancel, icon: const Icon(Icons.close)),
            IconButton(onPressed: onComplete, icon: const Icon(Icons.check)),
          ],
        ],
      ),
    );
  }
}
