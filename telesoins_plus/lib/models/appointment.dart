import 'package:telesoins_plus/models/user.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled,
  missed
}

class Appointment {
  final int id;
  final Patient patient;
  final Medecin medecin;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? reasonForVisit;
  final bool isUrgent;
  final DateTime createdAt;
  final String? notes;
  final String appointmentType; // 'video', 'chat', 'sms'

  Appointment({
    required this.id,
    required this.patient,
    required this.medecin,
    required this.dateTime,
    required this.status,
    this.reasonForVisit,
    this.isUrgent = false,
    required this.createdAt,
    this.notes,
    required this.appointmentType,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patient: Patient.fromJson(json['patient']),
      medecin: Medecin.fromJson(json['medecin']),
      dateTime: DateTime.parse(json['date_time']),
      status: _statusFromString(json['status']),
      reasonForVisit: json['reason_for_visit'],
      isUrgent: json['is_urgent'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      notes: json['notes'],
      appointmentType: json['appointment_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patient.id,
      'medecin_id': medecin.id,
      'date_time': dateTime.toIso8601String(),
      'status': status.toString().split('.').last,
      'reason_for_visit': reasonForVisit,
      'is_urgent': isUrgent,
      'created_at': createdAt.toIso8601String(),
      'notes': notes,
      'appointment_type': appointmentType,
    };
  }

  static AppointmentStatus _statusFromString(String status) {
    switch (status) {
      case 'pending':
        return AppointmentStatus.pending;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'missed':
        return AppointmentStatus.missed;
      default:
        return AppointmentStatus.pending;
    }
  }

  String get statusText {
    switch (status) {
      case AppointmentStatus.pending:
        return 'En attente';
      case AppointmentStatus.confirmed:
        return 'Confirmé';
      case AppointmentStatus.inProgress:
        return 'En cours';
      case AppointmentStatus.completed:
        return 'Terminé';
      case AppointmentStatus.cancelled:
        return 'Annulé';
      case AppointmentStatus.missed:
        return 'Manqué';
    }
  }

  String get appointmentTypeText {
    switch (appointmentType) {
      case 'video':
        return 'Vidéo';
      case 'chat':
        return 'Messagerie';
      case 'sms':
        return 'SMS';
      default:
        return 'Vidéo';
    }
  }
}