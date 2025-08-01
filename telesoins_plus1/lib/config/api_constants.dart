class ApiConstants {
  // Base URL
  static const String baseUrl = 'http://10.0.2.2:8000/api';  // Pour l'émulateur Android
  // static const String baseUrl = 'http://localhost:8000/api';  // Pour iOS Simulator
  // static const String baseUrl = 'https://telesoins-api.example.com/api';  // Pour la production
  
  // Authentification
  static const String login = '/auth/token/';
  static const String register = '/register/';
  static const String userProfile = '/user/profile/';
  
  // Dashboards
  static const String patientDashboard = '/patient/dashboard/';
  static const String medecinDashboard = '/medecin/dashboard/';
  
  // Rendez-vous
   static const String appointmentsUpcoming = '/consultations/appointments/upcoming/'; // Ajoutez cette ligne
  static const String appointments = '/consultations/appointments/';
  static const String upcomingAppointments = '/consultations/appointments/upcoming/';
  static const String urgentAppointments = '/consultations/appointments/urgent/';
  static const String appointmentsByDate = '/consultations/appointments/by_date/';
  
  // Consultations
  static const String consultations = '/consultations/consultations/';
  static const String activeConsultations = '/consultations/consultations/active/';
  
  // Prescriptions
  static const String prescriptions = '/consultations/prescriptions/';
  static const String activePrescriptions = '/consultations/prescriptions/active/';
  
  // Messages
  static const String messages = '/consultations/messages/';
  static const String unreadMessages = '/consultations/messages/unread/';
  
  // Premiers secours
  static const String firstAidModules = '/first-aid/modules/';
  static const String firstAidModulesByCategory = '/first-aid/modules/by_category/';
  static const String firstAidModulesByDifficulty = '/first-aid/modules/by_difficulty/';
  static const String firstAidContents = '/first-aid/contents/';
  static const String quizzes = '/first-aid/quizzes/';
  static const String quizResults = '/first-aid/results/';
  static const String quizResultsSummary = '/first-aid/results/summary/';
}