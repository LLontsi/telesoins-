import 'package:telesoins_plus/models/user.dart';

class Medication {
  final String name;
  final String dosage;
  final String frequency;
  final int durationDays;
  final String? specialInstructions;

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    this.specialInstructions,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      name: json['name'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      durationDays: json['duration_days'],
      specialInstructions: json['special_instructions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration_days': durationDays,
      'special_instructions': specialInstructions,
    };
  }
}

class Prescription {
  final int id;
  final Patient patient;
  final Medecin medecin;
  final DateTime issueDate;
  final List<Medication> medications;
  final String? diagnosis;
  final String? additionalInstructions;
  final DateTime expiryDate;
  final bool isFilled;
  final String? pdfUrl;

  Prescription({
    required this.id,
    required this.patient,
    required this.medecin,
    required this.issueDate,
    required this.medications,
    this.diagnosis,
    this.additionalInstructions,
    required this.expiryDate,
    this.isFilled = false,
    this.pdfUrl,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    List<Medication> medications = [];
    if (json['medications'] != null) {
      medications = List<Medication>.from(
        json['medications'].map((medJson) => Medication.fromJson(medJson))
      );
    }

    return Prescription(
      id: json['id'],
      patient: Patient.fromJson(json['patient']),
      medecin: Medecin.fromJson(json['medecin']),
      issueDate: DateTime.parse(json['issue_date']),
      medications: medications,
      diagnosis: json['diagnosis'],
      additionalInstructions: json['additional_instructions'],
      expiryDate: DateTime.parse(json['expiry_date']),
      isFilled: json['is_filled'] ?? false,
      pdfUrl: json['pdf_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patient.id,
      'medecin_id': medecin.id,
      'issue_date': issueDate.toIso8601String(),
      'medications': medications.map((m) => m.toJson()).toList(),
      'diagnosis': diagnosis,
      'additional_instructions': additionalInstructions,
      'expiry_date': expiryDate.toIso8601String(),
      'is_filled': isFilled,
      'pdf_url': pdfUrl,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiryDate);
}