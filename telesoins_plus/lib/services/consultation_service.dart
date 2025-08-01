import 'package:telesoins_plus/models/appointment.dart';
import 'package:telesoins_plus/models/consultation.dart';
import 'package:telesoins_plus/models/message.dart';
import 'package:telesoins_plus/models/prescription.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/api_service.dart';
import 'package:telesoins_plus/config/api_constants.dart';


// Classe utilitaire pour créer des objets fictifs
class MockService {
  // Crée un objet Appointment fictif
  static Appointment createMockAppointment(Map<String, dynamic> data, {int id = 100}) {
    // Créer un médecin fictif
    Medecin mockMedecin = createMockMedecin(data['medecin_id'] ?? 42);
    
    // Créer un patient fictif
    Patient mockPatient = createMockPatient();
    
    // Créer et retourner un rendez-vous fictif
    return Appointment(
      id: id,
      patient: mockPatient,
      medecin: mockMedecin,
      dateTime: data.containsKey('date_time') 
          ? DateTime.parse(data['date_time']) 
          : DateTime.now().add(Duration(days: 3)),
      status: AppointmentStatus.pending,
      reasonForVisit: data['reason_for_visit'],
      isUrgent: data['is_urgent'] ?? false,
      createdAt: DateTime.now(),
      appointmentType: data['appointment_type'],
    );
  }
  
  // Crée un médecin fictif
  static Medecin createMockMedecin(int id) {
    // Créer un médecin avec tous les paramètres nécessaires
    // Adaptez cette partie selon vos besoins
    return Medecin(
      // Ajoutez ici TOUS les paramètres requis par votre classe Medecin
      id: id,
      email: "docteur$id@example.com",
      firstName: "Docteur",
      lastName: "Numéro $id",
      phoneNumber: "+331234567$id",
      speciality: "Généraliste",
      // Ajoutez d'autres paramètres si nécessaire
    );
  }
  
  // Crée un patient fictif
  static Patient createMockPatient() {
     
  
    // Créer un patient avec tous les paramètres nécessaires
    // Adaptez cette partie selon vos besoins
    return Patient(
      // Ajoutez ici TOUS les paramètres requis par votre classe Patient
      id: 1,
      email: "patient@example.com",
      firstName: "Patient",
      lastName: "Test",
      phoneNumber: "+33987654321",
      // Ajoutez d'autres paramètres si nécessaire
    );
  }
}
  
class ConsultationService {
  final ApiService _apiService = ApiService();
  // Simule la liste des rendez-vous
  Future<List<Appointment>> getAppointments() async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    
    // Création de patients simulés
    final patient = Patient(
      id: 1,
      email: 'patient@example.com',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+33 6 12 34 56 78',
      dateOfBirth: DateTime(1985, 5, 15),
    );
    
    // Création de médecins simulés
    final medecins = [
      Medecin(
        id: 1,
        email: 'dr.martin@example.com',
        firstName: 'Dr.',
        lastName: 'Martin',
        phoneNumber: '+33 6 98 76 54 32',
        speciality: 'Généraliste',
      ),
      Medecin(
        id: 2,
        email: 'dr.petit@example.com',
        firstName: 'Dr.',
        lastName: 'Petit',
        phoneNumber: '+33 6 11 22 33 44',
        speciality: 'Cardiologue',
      ),
      Medecin(
        id: 3,
        email: 'dr.roux@example.com',
        firstName: 'Dr.',
        lastName: 'Roux',
        phoneNumber: '+33 6 55 44 33 22',
        speciality: 'Dermatologue',
      ),
    ];
    
    // Création de rendez-vous variés
    return [
      // Rendez-vous à venir
      Appointment(
        id: 1,
        patient: patient,
        medecin: medecins[0],
        dateTime: now.add(const Duration(days: 2, hours: 3)),
        status: AppointmentStatus.confirmed,
        reasonForVisit: 'Consultation de routine',
        isUrgent: false,
        createdAt: now.subtract(const Duration(days: 3)),
        appointmentType: 'video',
        notes: 'Apporter les derniers résultats d\'analyses',
      ),
      Appointment(
        id: 2,
        patient: patient,
        medecin: medecins[1],
        dateTime: now.add(const Duration(days: 5, hours: 1, minutes: 30)),
        status: AppointmentStatus.confirmed,
        reasonForVisit: 'Suivi cardiaque',
        isUrgent: true,
        createdAt: now.subtract(const Duration(days: 1)),
        appointmentType: 'video',
      ),
      Appointment(
        id: 3,
        patient: patient,
        medecin: medecins[2],
        dateTime: now.add(const Duration(days: 7, hours: 2, minutes: 15)),
        status: AppointmentStatus.pending,
        reasonForVisit: 'Examen de la peau',
        isUrgent: false,
        createdAt: now.subtract(const Duration(hours: 12)),
        appointmentType: 'chat',
      ),
      
      // Rendez-vous passés
      Appointment(
        id: 4,
        patient: patient,
        medecin: medecins[0],
        dateTime: now.subtract(const Duration(days: 5, hours: 2)),
        status: AppointmentStatus.completed,
        reasonForVisit: 'Vaccination grippe',
        isUrgent: false,
        createdAt: now.subtract(const Duration(days: 10)),
        appointmentType: 'video',
      ),
      Appointment(
        id: 5,
        patient: patient,
        medecin: medecins[1],
        dateTime: now.subtract(const Duration(days: 15, hours: 4)),
        status: AppointmentStatus.cancelled,
        reasonForVisit: 'Douleurs thoraciques',
        isUrgent: true,
        createdAt: now.subtract(const Duration(days: 20)),
        appointmentType: 'video',
      ),
      Appointment(
        id: 6,
        patient: patient,
        medecin: medecins[2],
        dateTime: now.subtract(const Duration(days: 30)),
        status: AppointmentStatus.missed,
        reasonForVisit: 'Éruption cutanée',
        isUrgent: false,
        createdAt: now.subtract(const Duration(days: 35)),
        appointmentType: 'chat',
      ),
    ];
  }
  
  // Récupérer les détails d'une consultation
  Future<Consultation> getConsultation(int id) async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    
    // Création d'un patient simulé
    final patient = Patient(
      id: 1,
      email: 'patient@example.com',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+33 6 12 34 56 78',
    );
    
    // Création d'un médecin simulé
    final medecin = Medecin(
      id: 1,
      email: 'dr.martin@example.com',
      firstName: 'Dr.',
      lastName: 'Martin',
      phoneNumber: '+33 6 98 76 54 32',
      speciality: 'Généraliste',
    );
    
    // Création d'un rendez-vous simulé
    final appointment = Appointment(
      id: id,
      patient: patient,
      medecin: medecin,
      dateTime: now.add(const Duration(minutes: 30)),
      status: AppointmentStatus.confirmed,
      reasonForVisit: 'Consultation de routine',
      isUrgent: false,
      createdAt: now.subtract(const Duration(days: 3)),
      appointmentType: 'video',
    );
    
    // Création de messages simulés
    final messages = [
      Message(
        id: 1,
        consultationId: id,
        sender: patient,
        content: 'Bonjour Docteur, je vous contacte pour mon suivi médical.',
        type: MessageType.text,
        timestamp: now.subtract(const Duration(minutes: 30)),
        isRead: true,
      ),
      Message(
        id: 2,
        consultationId: id,
        sender: medecin,
        content: 'Bonjour, comment puis-je vous aider aujourd\'hui?',
        type: MessageType.text,
        timestamp: now.subtract(const Duration(minutes: 25)),
        isRead: true,
      ),
      Message(
        id: 3,
        consultationId: id,
        sender: patient,
        content: 'J\'ai des maux de tête depuis quelques jours.',
        type: MessageType.text,
        timestamp: now.subtract(const Duration(minutes: 20)),
        isRead: true,
      ),
    ];
    
    // Création d'ordonnances simulées
    final prescriptions = [
      Prescription(
        id: 1,
        patient: patient,
        medecin: medecin,
        issueDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 30)),
        medications: [
          Medication(
            name: 'Paracétamol',
            dosage: '1000mg',
            frequency: '3 fois par jour',
            durationDays: 7,
          ),
        ],
        diagnosis: 'Céphalées de tension',
      ),
    ];
    
    // Création d'une consultation simulée
    return Consultation(
      id: id,
      appointment: appointment,
      startTime: now.subtract(const Duration(minutes: 35)),
      status: ConsultationStatus.inProgress,
      messages: messages,
      prescriptions: prescriptions,
    );
  }
  
  // Simuler le démarrage d'une consultation
  Future<Consultation> startConsultation(int appointmentId) async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(seconds: 1));
    
    return getConsultation(100); // ID de consultation arbitraire
  }
  
  // Simuler l'annulation d'un rendez-vous
  Future<void> cancelAppointment(int id) async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(seconds: 1));
    
    // Rien à retourner, juste simuler un succès
    return;
  }
  
  // Terminer une consultation
Future<Appointment> endConsultation(int appointmentId, Map<String, dynamic> endData) async {
  // Simulation d'un délai d'appel API
  await Future.delayed(const Duration(seconds: 1));
  
  // Dans une application réelle, vous feriez un appel API pour mettre à jour
  // le statut de la consultation et ajouter des notes ou des informations de suivi
  
  // Pour simuler, nous créons un rendez-vous fictif avec un statut "completed"
  Medecin mockMedecin = Medecin(
    id: 42,
    email: "docteur@example.com",
    firstName: "Dr",
    lastName: "Dupont",
    phoneNumber: "+33123456789",
    speciality: "Généraliste",
    // Ajoutez d'autres paramètres requis
  );
  
  Patient mockPatient = Patient(
    id: 1,
    email: "patient@example.com",
    firstName: "Jean",
    lastName: "Martin",
    phoneNumber: "+33987654321",
    // Ajoutez d'autres paramètres requis
  );
  
  return Appointment(
    id: appointmentId,
    patient: mockPatient,
    medecin: mockMedecin,
    dateTime: DateTime.now().subtract(Duration(hours: 1)),  // La consultation a eu lieu il y a une heure
    status: AppointmentStatus.completed,  // Statut terminé
    reasonForVisit: endData['reason_for_visit'] ?? "Consultation",
    isUrgent: endData['is_urgent'] ?? false,
    createdAt: DateTime.now().subtract(Duration(days: 1)),
    notes: endData['notes'] ?? "Consultation terminée avec succès",
    appointmentType: endData['appointment_type'] ?? "video",
  );
}
 
// Mettre à jour le statut d'une consultation
Future<Appointment> updatedConsultation(int appointmentId, Map<String, dynamic> updateData) async {
  // Simulation d'un délai d'appel API
  await Future.delayed(const Duration(seconds: 1));
  
  // Dans une application réelle, vous feriez un appel API pour mettre à jour
  // les informations de la consultation
  
  // Pour simuler, nous créons un rendez-vous fictif avec les données mises à jour
  Medecin mockMedecin = Medecin(
    id: updateData['medecin_id'] ?? 42,
    email: "docteur@example.com",
    firstName: "Dr",
    lastName: "Dupont",
    phoneNumber: "+33123456789",
    speciality: "Généraliste",
    // Ajoutez d'autres paramètres requis
  );
  
  Patient mockPatient = Patient(
    id: 1,
    email: "patient@example.com",
    firstName: "Jean",
    lastName: "Martin",
    phoneNumber: "+33987654321",
   
    // Ajoutez d'autres paramètres requis
  );
  
  // Déterminer le statut en fonction des données de mise à jour
  AppointmentStatus status = AppointmentStatus.pending;
  if (updateData.containsKey('status')) {
    // Convertir la chaîne de statut en enum AppointmentStatus
    try {
      status = AppointmentStatus.values.firstWhere(
        (s) => s.toString().split('.').last == updateData['status']
      );
    } catch (_) {
      // En cas d'erreur, conserver le statut par défaut
    }
  }
  
  return Appointment(
    id: appointmentId,
    patient: mockPatient,
    medecin: mockMedecin,
    dateTime: updateData.containsKey('date_time') 
        ? DateTime.parse(updateData['date_time']) 
        : DateTime.now().add(Duration(days: 1)),
    status: status,
    reasonForVisit: updateData['reason_for_visit'] ?? "Consultation mise à jour",
    isUrgent: updateData['is_urgent'] ?? false,
    createdAt: DateTime.now().subtract(Duration(days: 1)),
    notes: updateData['notes'],
    appointmentType: updateData['appointment_type'] ?? "video",
  );
} 
 // Créer un nouveau rendez-vous
Future<Appointment> createAppointment(Map<String, dynamic> appointmentData) async {
  // Simulation d'un délai d'appel API
  await Future.delayed(const Duration(seconds: 1));
  
  // Utiliser un service mock pour créer un rendez-vous fictif
  return MockService.createMockAppointment(appointmentData);
}

// Mettre à jour un rendez-vous
Future<Appointment> updateAppointment(int id, Map<String, dynamic> appointmentData) async {
  // Simulation d'un délai d'appel API
  await Future.delayed(const Duration(seconds: 1));
  
  // Utiliser un service mock pour mettre à jour un rendez-vous fictif
  return MockService.createMockAppointment(appointmentData, id: id);
}

  // Simuler l'envoi d'un message
  Future<Message> sendMessage(int consultationId, Map<String, dynamic> messageData) async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Création d'un utilisateur simulé (utilisateur actuel)
    final currentUser = Patient(
      id: 1,
      email: 'patient@example.com',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+33 6 12 34 56 78',
    );
    
    // Création d'un message simulé
    return Message(
      id: DateTime.now().millisecondsSinceEpoch,
      consultationId: consultationId,
      sender: currentUser,
      content: messageData['content'],
      type: MessageType.text,
      timestamp: DateTime.now(),
      isRead: false,
    );
  }
  
  // Simuler la création d'une ordonnance
  Future<Prescription> createPrescription(Map<String, dynamic> prescriptionData) async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(seconds: 1));
    
    // Création d'un patient simulé
    final patient = Patient(
      id: 1,
      email: 'patient@example.com',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+33 6 12 34 56 78',
    );
    
    // Création d'un médecin simulé
    final medecin = Medecin(
      id: 1,
      email: 'dr.martin@example.com',
      firstName: 'Dr.',
      lastName: 'Martin',
      phoneNumber: '+33 6 98 76 54 32',
      speciality: 'Généraliste',
    );
    
    // Création d'une ordonnance simulée
    return Prescription(
      id: DateTime.now().millisecondsSinceEpoch,
      patient: patient,
      medecin: medecin,
      issueDate: DateTime.now(),
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      medications: [
        Medication(
          name: 'Paracétamol',
          dosage: '1000mg',
          frequency: '3 fois par jour',
          durationDays: 7,
        ),
      ],
      diagnosis: prescriptionData['diagnosis'] ?? 'Diagnostic non spécifié',
    );
  }
  
  // Récupérer les prescriptions d'un patient
  Future<List<Prescription>> getPatientPrescriptions() async {
    // Simulation d'un délai d'appel API
    await Future.delayed(const Duration(milliseconds: 800));
    
    final now = DateTime.now();
    
    // Création d'un patient simulé
    final patient = Patient(
      id: 1,
      email: 'patient@example.com',
      firstName: 'Jean',
      lastName: 'Dupont',
      phoneNumber: '+33 6 12 34 56 78',
    );
    
    // Création de médecins simulés
    final medecins = [
      Medecin(
        id: 1,
        email: 'dr.martin@example.com',
        firstName: 'Dr.',
        lastName: 'Martin',
        phoneNumber: '+33 6 98 76 54 32',
        speciality: 'Généraliste',
      ),
      Medecin(
        id: 2,
        email: 'dr.petit@example.com',
        firstName: 'Dr.',
        lastName: 'Petit',
        phoneNumber: '+33 6 11 22 33 44',
        speciality: 'Cardiologue',
      ),
    ];
    
    // Création d'ordonnances simulées
    return [
      Prescription(
        id: 1,
        patient: patient,
        medecin: medecins[0],
        issueDate: now.subtract(const Duration(days: 5)),
        expiryDate: now.add(const Duration(days: 25)),
        medications: [
          Medication(
            name: 'Paracétamol',
            dosage: '1000mg',
            frequency: '3 fois par jour',
            durationDays: 7,
          ),
          Medication(
            name: 'Ibuprofène',
            dosage: '400mg',
            frequency: '2 fois par jour',
            durationDays: 5,
          ),
        ],
        diagnosis: 'Grippe saisonnière',
      ),
      Prescription(
        id: 2,
        patient: patient,
        medecin: medecins[1],
        issueDate: now.subtract(const Duration(days: 30)),
        expiryDate: now.subtract(const Duration(days: 1)),
        medications: [
          Medication(
            name: 'Amlodipine',
            dosage: '5mg',
            frequency: '1 fois par jour',
            durationDays: 30,
          ),
        ],
        diagnosis: 'Hypertension légère',
        additionalInstructions: 'Surveiller la tension artérielle régulièrement',
      ),
      Prescription(
        id: 3,
        patient: patient,
        medecin: medecins[0],
        issueDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(const Duration(days: 29)),
        medications: [
          Medication(
            name: 'Amoxicilline',
            dosage: '500mg',
            frequency: '3 fois par jour',
            durationDays: 7,
          ),
        ],
        diagnosis: 'Infection ORL',
        additionalInstructions: 'Prendre pendant les repas',
      ),
    ];
  }
   Future<Prescription> getPrescriptionDetails(int prescriptionId) async {
    try {
      // Appel à l'API pour récupérer les détails de l'ordonnance
      final response = await _apiService.get('/prescriptions/$prescriptionId/');
      
      if (response.statusCode == 200) {
        return Prescription.fromJson(response.data);
      } else {
        throw 'Erreur serveur: ${response.statusCode}';
      }
    } catch (e) {
      // Pour développement/débogage, vous pouvez retourner des données fictives
      if (true) { // Changez à false en production
        return _getMockPrescription(prescriptionId);
      }
      throw 'Erreur lors de la récupération des détails de l\'ordonnance: $e';
    }
  }

  // Données fictives pour le développement et les tests
  Prescription _getMockPrescription(int prescriptionId) {
    final now = DateTime.now();
    final issueDate = now.subtract(const Duration(days: 7));
    final expiryDate = issueDate.add(const Duration(days: 30));
    
    return Prescription(
      id: prescriptionId,
      patient: Patient(
        id: 1,
        firstName: 'Marie',
        lastName: 'Dupont',
        email: 'marie.dupont@example.com',
        phoneNumber: '0612345678',
        dateOfBirth: DateTime(1985, 5, 10),
      ),
      medecin: Medecin(
        id: 2,
        firstName: 'Jean',
        lastName: 'Martin',
        email: 'dr.martin@telesoins.fr',
        phoneNumber: '0687654321',
        speciality: 'Médecine générale',
        licenseNumber: '10987654321',
      ),
      issueDate: issueDate,
      expiryDate: expiryDate,
      medications: [
        Medication(
          name: 'Paracétamol',
          dosage: '1000mg',
          frequency: '3 fois par jour',
          durationDays: 7,
          specialInstructions: 'À prendre après les repas',
        ),
        Medication(
          name: 'Ibuprofène',
          dosage: '400mg',
          frequency: '2 fois par jour',
          durationDays: 5,
          specialInstructions: 'Ne pas prendre à jeun',
        ),
      ],
      diagnosis: 'Lombalgie aiguë',
      additionalInstructions: 'Repos relatif pendant 3 jours, application de chaleur localement 20 minutes 3 fois par jour',
      isFilled: false,
      pdfUrl: 'https://api.telesoins.fr/prescriptions/$prescriptionId/download',
    );
  }

}