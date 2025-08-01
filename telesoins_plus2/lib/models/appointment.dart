import 'package:telesoins_plus2/models/user.dart';

class Appointment {
  final String id;
  final User patient;
  final User medecin;
  final DateTime datetime;
  final String status;
  final String reason;
  final String? notes;
  final bool isUrgent;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Appointment({
    required this.id,
    required this.patient,
    required this.medecin,
    required this.datetime,
    required this.status,
    required this.reason,
    this.notes,
    required this.isUrgent,
    required this.createdAt,
    required this.updatedAt,
  });
  
  String get statusDisplay {
    switch (status) {
      case 'pending': return 'En attente';
      case 'confirmed': return 'Confirmé';
      case 'canceled': return 'Annulé';
      case 'completed': return 'Terminé';
      default: return 'Inconnu';
    }
  }
  
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      patient: User.fromJson(json['patient']),
      medecin: User.fromJson(json['medecin']),
      datetime: DateTime.parse(json['datetime']),
      status: json['status'],
      reason: json['reason'],
      notes: json['notes'],
      isUrgent: json['is_urgent'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient': patient.id,
      'medecin': medecin.id,
      'datetime': datetime.toIso8601String(),
      'status': status,
      'reason': reason,
      'notes': notes,
      'is_urgent': isUrgent,
    };
  }
  
  // Méthode pour créer un nouvel Appointment à partir de données partielles (pour la création)
  factory Appointment.create({
    required String medecinId,
    required DateTime datetime,
    required String reason,
    String? notes,
    bool isUrgent = false,
  }) {
    return Appointment(
      id: '',  // Sera généré par le backend
      patient: User(
        id: '',
        email: '',
        firstName: '',
        lastName: '',
        role: 'patient',
        isVerified: false,
        createdAt: DateTime.now(),
      ),  // Sera rempli par le backend
      medecin: User(
        id: medecinId,
        email: '',
        firstName: '',
        lastName: '',
        role: 'medecin',
        isVerified: false,
        createdAt: DateTime.now(),
      ),  // Sera rempli par le backend
      datetime: datetime,
      status: 'pending',
      reason: reason,
      notes: notes,
      isUrgent: isUrgent,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}