class Prescription {
  final String id;
  final String consultationId;
  final String patientName;
  final String details;
  final DateTime createdAt;
  final DateTime? validUntil;
  
  Prescription({
    required this.id,
    required this.consultationId,
    required this.patientName,
    required this.details,
    required this.createdAt,
    this.validUntil,
  });

  // Création à partir de JSON (réponse API)
  factory Prescription.fromJson(Map<String, dynamic> json) {
    return Prescription(
      id: json['id'],
      consultationId: json['consultation']['id'],
      patientName: json['consultation']['patient']['full_name'] ?? 'Patient',
      details: json['details'],
      createdAt: DateTime.parse(json['created_at']),
      validUntil: json['valid_until'] != null 
          ? DateTime.parse(json['valid_until']) 
          : null,
    );
  }

  // Conversion en JSON pour envoi API
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'consultation': consultationId,
      'details': details,
    };

    if (validUntil != null) {
      data['valid_until'] = validUntil!.toIso8601String().split('T').first;
    }

    return data;
  }

  // Déterminer si la prescription est active
  bool get isActive {
    if (validUntil == null) return true;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return validUntil!.isAtSameMomentAs(today) || validUntil!.isAfter(today);
  }

  // Format lisible de la date de validité
  String get validUntilFormatted {
    if (validUntil == null) {
      return 'Validité illimitée';
    }
    
    return '${validUntil!.day.toString().padLeft(2, '0')}/${validUntil!.month.toString().padLeft(2, '0')}/${validUntil!.year}';
  }

  // Format lisible de la date de création
  String get createdAtFormatted {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }
}