class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? profilePhotoUrl;
  final String userType; // 'patient' ou 'medecin'
  final String? speciality; // Pour les médecins uniquement
  final DateTime? dateOfBirth; // Pour les patients uniquement
  final String? address;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.profilePhotoUrl,
    required this.userType,
    this.speciality,
    this.dateOfBirth,
    this.address,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      profilePhotoUrl: json['profile_photo_url'],
      userType: json['user_type'],
      speciality: json['speciality'],
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'profile_photo_url': profilePhotoUrl,
      'user_type': userType,
      'speciality': speciality,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'address': address,
    };
  }
}

class Patient extends User {
  final String? bloodGroup;
  final List<String>? allergies;
  final List<String>? chronicConditions;

  Patient({
    required int id,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? profilePhotoUrl,
    DateTime? dateOfBirth,
    String? address,
    this.bloodGroup,
    this.allergies,
    this.chronicConditions,
  }) : super(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    profilePhotoUrl: profilePhotoUrl,
    userType: 'patient',
    dateOfBirth: dateOfBirth,
    address: address,
  );

  factory Patient.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    return Patient(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phoneNumber: user.phoneNumber,
      profilePhotoUrl: user.profilePhotoUrl,
      dateOfBirth: user.dateOfBirth,
      address: user.address,
      bloodGroup: json['blood_group'],
      allergies: json['allergies'] != null 
          ? List<String>.from(json['allergies']) 
          : null,
      chronicConditions: json['chronic_conditions'] != null 
          ? List<String>.from(json['chronic_conditions']) 
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['blood_group'] = bloodGroup;
    data['allergies'] = allergies;
    data['chronic_conditions'] = chronicConditions;
    return data;
  }
}

class Medecin extends User {
  final String? licenseNumber;
  final List<String>? workingDays;
  final String? workingHours;
  final bool isAvailableForEmergency;

  Medecin({
    required int id,
    required String email,
    required String firstName,
    required String lastName,
    required String phoneNumber,
    String? profilePhotoUrl,
    required String speciality,
    String? address,
    this.licenseNumber,
    this.workingDays,
    this.workingHours,
    this.isAvailableForEmergency = false,
  }) : super(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phoneNumber: phoneNumber,
    profilePhotoUrl: profilePhotoUrl,
    userType: 'medecin',
    speciality: speciality,
    address: address,
  );

  factory Medecin.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    return Medecin(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      phoneNumber: user.phoneNumber,
      profilePhotoUrl: user.profilePhotoUrl,
      speciality: user.speciality ?? 'Généraliste',
      address: user.address,
      licenseNumber: json['license_number'],
      workingDays: json['working_days'] != null 
          ? List<String>.from(json['working_days']) 
          : null,
      workingHours: json['working_hours'],
      isAvailableForEmergency: json['is_available_for_emergency'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data['license_number'] = licenseNumber;
    data['working_days'] = workingDays;
    data['working_hours'] = workingHours;
    data['is_available_for_emergency'] = isAvailableForEmergency;
    return data;
  }
}