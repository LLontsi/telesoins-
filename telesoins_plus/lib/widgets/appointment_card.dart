import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/models/appointment.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final bool isPatientView;

  const AppointmentCard({
    Key? key,
    required this.appointment,
    this.onTap,
    this.onCancel,
    this.isPatientView = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMMd('fr');
    final timeFormat = DateFormat.Hm('fr');
    
    Color statusColor;
    switch (appointment.status) {
      case AppointmentStatus.confirmed:
        statusColor = AppTheme.successColor;
        break;
      case AppointmentStatus.pending:
        statusColor = AppTheme.warningColor;
        break;
      case AppointmentStatus.cancelled:
      case AppointmentStatus.missed:
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.primaryColor;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: appointment.isUrgent ? AppTheme.urgentColor : Colors.transparent,
          width: appointment.isUrgent ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (appointment.isUrgent)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: const BoxDecoration(
                  color: AppTheme.urgentColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'URGENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isPatientView 
                              ? 'Dr. ${appointment.medecin.lastName}'
                              : appointment.patient.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          appointment.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(appointment.dateTime),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeFormat.format(appointment.dateTime),
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getAppointmentTypeIcon(appointment.appointmentType),
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        appointment.appointmentTypeText,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isPatientView && appointment.medecin.speciality != null) ...[
                        const Text(' • '),
                        Text(
                          appointment.medecin.speciality!,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (appointment.reasonForVisit != null && appointment.reasonForVisit!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Motif: ${appointment.reasonForVisit}',
                      style: const TextStyle(
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (appointment.status == AppointmentStatus.confirmed ||
                      appointment.status == AppointmentStatus.pending) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onCancel != null)
                          OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Annuler'),
                          ),
                        const SizedBox(width: 8),
                        if (onTap != null)
                          ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Détails'),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAppointmentTypeIcon(String type) {
    switch (type) {
      case 'video':
        return Icons.videocam;
      case 'chat':
        return Icons.chat;
      case 'sms':
        return Icons.sms;
      default:
        return Icons.videocam;
    }
  }
}