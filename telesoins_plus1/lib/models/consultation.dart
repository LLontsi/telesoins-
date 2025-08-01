import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/models/appointment.dart';

class Consultation {
  final String id;
  final Appointment? appointment;
  final User patient;
  final User medecin;
  final String type;
  final DateTime startTime;
  final DateTime? endTime;
  final String? summary;
  final String? diagnosis;
  final List<Prescription>? prescriptions;
  final List<Message>? messages;
  
  Consultation({
    required this.id,
    this.appointment,
    required this.patient,
    required this.medecin,
    required this.type,
    required this.startTime,
    this.endTime,
    this.summary,
    this.diagnosis,
    this.prescriptions,
    this.messages,
  });
  
  bool get isActive => endTime == null;
  
  String get typeDisplay {
    switch (type) {
      case 'video': return 'Vidéo';
      case 'message': return 'Message';
      case 'sms': return 'SMS';
      default: return 'Inconnu';
    }
  }
  
  factory Consultation.fromJson(Map<String, dynamic> json) {
    return Consultation(
      id: json['id'],
      appointment: json['appointment'] != null 
        ? Appointment.fromJson(json['appointment']) 
        : null,
      patient: User.fromJson(json['patient']),
      medecin: User.fromJson(json['medecin']),
      type: json['type'],
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null 
        ? DateTime.parse(json['end_time']) 
        : null,
      summary: json['summary'],
      diagnosis: json['diagnosis'],
      prescriptions: json['prescriptions'] != null 
        ? (json['prescriptions'] as List)
            .map((p) => Prescription.fromJson(p))
            .toList() 
        : null,
      messages: json['messages'] != null 
        ? (json['messages'] as List)
            .map((m) => Message.fromJson(m))
            .toList() 
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'appointment': appointment?.id,
      'patient': patient.id,
      'medecin': medecin.id,
      'type': type,
      'summary': summary,
      'diagnosis': diagnosis,
    };
  }
}

class Prescription {
  final String id;
  final String consultationId;
  final String details;
  final DateTime createdAt;
  final DateTime? validUntil;
  
  Prescription({
    required this.id,
    required this.consultationId,
    required this.details,
    required this.createdAt,
    this.validUntil,
  });
  
  bool get isActive {
    if (validUntil == null) return true;
    return validUntil!.isAfter(DateTime.now());
  }
  
  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      consultationId: json['consultation'],
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
      validUntil: json['valid_until'] != null 
        ? DateTime.parse(json['valid_until']) 
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'consultation': consultationId,
      'details': details,
      'valid_until': validUntil?.toIso8601String(),
    };
  }
}

class Message {
  final String id;
  final String consultationId;
  final User sender;
  final String content;
  final String? attachmentUrl;
  final DateTime timestamp;
  final bool isRead;
  
  Message({
    required this.id,
    required this.consultationId,
    required this.sender,
    required this.content,
    this.attachmentUrl,
    required this.timestamp,
    required this.isRead,
  });
  
  bool get isSentByMe => sender.role != 'medecin';  // Simpliste
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      consultationId: json['consultation'],
      sender: User.fromJson(json['sender']),
      content: json['content'],
      attachmentUrl: json['attachment'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'consultation': consultationId,
      'content': content,
      // L'attachment sera géré séparément
    };
  }
}