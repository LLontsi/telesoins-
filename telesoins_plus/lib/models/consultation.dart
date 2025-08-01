import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/models/message.dart';
import 'package:telesoins_plus/models/prescription.dart';

enum ConsultationStatus {
  scheduled,
  inProgress,
  completed,
  cancelled
}

class Consultation {
  final int id;
  final Appointment appointment;
  final DateTime startTime;
  final DateTime? endTime;
  final ConsultationStatus status;
  final List<Message> messages;
  final List<Prescription>? prescriptions;
  final String? diagnosis;
  final String? treatmentPlan;
  final String? followUpInstructions;
  final List<String>? attachments;

  Consultation({
    required this.id,
    required this.appointment,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.messages,
    this.prescriptions,
    this.diagnosis,
    this.treatmentPlan,
    this.followUpInstructions,
    this.attachments,
  });

  factory Consultation.fromJson(Map<String, dynamic> json) {
    List<Message> messages = [];
    if (json['messages'] != null) {
      messages = List<Message>.from(
        json['messages'].map((messageJson) => Message.fromJson(messageJson))
      );
    }

    List<Prescription>? prescriptions;
    if (json['prescriptions'] != null) {
      prescriptions = List<Prescription>.from(
        json['prescriptions'].map((prescriptionJson) => Prescription.fromJson(prescriptionJson))
      );
    }

    List<String>? attachments;
    if (json['attachments'] != null) {
      attachments = List<String>.from(json['attachments']);
    }

    return Consultation(
      id: json['id'],
      appointment: Appointment.fromJson(json['appointment']),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null 
          ? DateTime.parse(json['end_time']) 
          : null,
      status: _statusFromString(json['status']),
      messages: messages,
      prescriptions: prescriptions,
      diagnosis: json['diagnosis'],
      treatmentPlan: json['treatment_plan'],
      followUpInstructions: json['follow_up_instructions'],
      attachments: attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment_id': appointment.id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.toString().split('.').last,
      'diagnosis': diagnosis,
      'treatment_plan': treatmentPlan,
      'follow_up_instructions': followUpInstructions,
      'attachments': attachments,
    };
  }

  static ConsultationStatus _statusFromString(String status) {
    switch (status) {
      case 'scheduled':
        return ConsultationStatus.scheduled;
      case 'in_progress':
        return ConsultationStatus.inProgress;
      case 'completed':
        return ConsultationStatus.completed;
      case 'cancelled':
        return ConsultationStatus.cancelled;
      default:
        return ConsultationStatus.scheduled;
    }
  }

  String get statusText {
    switch (status) {
      case ConsultationStatus.scheduled:
        return 'Planifiée';
      case ConsultationStatus.inProgress:
        return 'En cours';
      case ConsultationStatus.completed:
        return 'Terminée';
      case ConsultationStatus.cancelled:
        return 'Annulée';
    }
  }

  // Durée de la consultation en minutes
  int get durationInMinutes {
    if (endTime == null) {
      return 0;
    }
    return endTime!.difference(startTime).inMinutes;
  }
}