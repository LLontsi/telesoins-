class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final bool isVerified;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.profilePhotoUrl,
    required this.isVerified,
    required this.createdAt,
  });
  
  String get fullName => '$firstName $lastName';
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'],
      phoneNumber: json['phone_number'],
      profilePhotoUrl: json['profile_photo'],
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'phone_number': phoneNumber,
      'profile_photo': profilePhotoUrl,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PatientProfile {
  final User user;
  final DateTime? dateOfBirth;
  final Map<String, dynamic> emergencyContacts;
  final String? medicalHistory;
  final String? allergies;
  final String? bloodType;
  final Map<String, dynamic> firstAidProgress;
  
  PatientProfile({
    required this.user,
    this.dateOfBirth,
    required this.emergencyContacts,
    this.medicalHistory,
    this.allergies,
    this.bloodType,
    required this.firstAidProgress,
  });
  
  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      user: User.fromJson(json['user']),
      dateOfBirth: json['date_of_birth'] != null 
        ? DateTime.parse(json['date_of_birth']) 
        : null,
      emergencyContacts: json['emergency_contacts'] ?? {},
      medicalHistory: json['medical_history'],
      allergies: json['allergies'],
      bloodType: json['blood_type'],
      firstAidProgress: json['first_aid_progress'] ?? {},
    );
  }
}

class MedecinProfile {
  final User user;
  final String speciality;
  final String licenceNumber;
  final int yearsOfExperience;
  final Map<String, dynamic> availableHours;
  final Map<String, dynamic> triageProtocols;
  
  MedecinProfile({
    required this.user,
    required this.speciality,
    required this.licenceNumber,
    required this.yearsOfExperience,
    required this.availableHours,
    required this.triageProtocols,
  });
  
  factory MedecinProfile.fromJson(Map<String, dynamic> json) {
    return MedecinProfile(
      user: User.fromJson(json['user']),
      speciality: json['speciality'],
      licenceNumber: json['licence_number'],
      yearsOfExperience: json['years_of_experience'] ?? 0,
      availableHours: json['available_hours'] ?? {},
      triageProtocols: json['triage_protocols'] ?? {},
    );
  }
}