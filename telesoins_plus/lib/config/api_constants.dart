class ApiConstants {
  // URL de base - à remplacer par votre URL réelle
  static const String baseUrl = 'https://api.telesoins-plus.com/api';
  
  // Endpoints d'authentification
  static const String login = '/accounts/login/';
  static const String register = '/accounts/register/';
  static const String refreshToken = '/accounts/token/refresh/';
  
  // Endpoints des utilisateurs
  static const String userProfile = '/accounts/profile/';
  static const String updateProfile = '/accounts/profile/update/';
  
  // Endpoints des rendez-vous
  static const String appointments = '/consultations/appointments/';
  static const String createAppointment = '/consultations/appointments/create/';
  
  // Endpoints des consultations
  static const String consultations = '/consultations/';
  static const String consultationDetail = '/consultations/{id}/';
  static const String messages = '/consultations/{id}/messages/';
  
  // Endpoints des prescriptions
  static const String prescriptions = '/consultations/prescriptions/';
  static const String prescriptionDetail = '/consultations/prescriptions/{id}/';
  
  // Endpoints premiers secours
  static const String firstAidModules = '/premiers_secours/modules/';
  static const String firstAidContent = '/premiers_secours/content/';
  static const String firstAidQuiz = '/premiers_secours/quiz/';
  
  // Timeouts
  static const int connectionTimeout = 15000; // 15 secondes
  static const int receiveTimeout = 15000; // 15 secondes
}