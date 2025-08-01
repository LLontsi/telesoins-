import 'package:flutter/material.dart';
import 'package:telesoins_plus/screens/common/login_screen.dart';
import 'package:telesoins_plus/screens/common/splash_screen.dart';
import 'package:telesoins_plus/screens/common/signup_screen.dart';
import 'package:telesoins_plus/screens/common/profile_screen.dart';
import 'package:telesoins_plus/screens/patient/home_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/emergency_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/medical_record_screen.dart' as patient;
import 'package:telesoins_plus/screens/medecin/home_screen.dart' as medecin;
import 'package:telesoins_plus/screens/patient/appointments_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/appointment_details_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/prescriptions_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/prescription_details_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/messaging_screen.dart' as patient;
import 'package:telesoins_plus/screens/patient/book_appointment_screen.dart' as patient;
import 'package:telesoins_plus/screens/medecin/appointments_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/new_consultation_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/new_prescription_screen.dart' as medecin;
import 'package:telesoins_plus/screens/patient/consultation_screen.dart' as patient;
import 'package:telesoins_plus/screens/medecin/consultation_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/patient_details_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/patient_list_screen.dart' as medecin;
import 'package:telesoins_plus/screens/patient/first_aid/first_aid_menu.dart';
import 'package:telesoins_plus/screens/patient/first_aid/module_screen.dart';
import 'package:telesoins_plus/screens/medecin/messaging_screen.dart' as medecin;
import 'package:telesoins_plus/screens/notifications_screen.dart';


class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      
      case '/signup':
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      
      // Routes pour les patients
      case '/patient/home':
        return MaterialPageRoute(builder: (_) => const patient.HomeScreen());
      
      case '/patient/appointments':
        return MaterialPageRoute(builder: (_) => const patient.AppointmentsScreen());
      
      case '/patient/emergency':
        return MaterialPageRoute(builder: (_) => const patient.EmergencyScreen());
      
      case '/patient/appointment_details':
        final int appointmentId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) =>  patient.AppointmentDetailsScreen(appointmentId: appointmentId));
      
      case '/patient/medical_history':
        
        return MaterialPageRoute(
          builder: (_) => patient.MedicalRecordScreen( ),
        );
      
      case '/medecin/new_prescription':
        final int? patientId = settings.arguments as int?;
        return MaterialPageRoute(
          builder: (_) => medecin.NewPrescriptionScreen(patientId: patientId)
        );

      case '/medecin/new_consultation':
          final int? patientId = settings.arguments as int?;
          return MaterialPageRoute(
            builder: (_) => medecin.NewConsultationScreen(patientId: patientId)
          );

      case '/patient/book_appointment':
        return MaterialPageRoute(builder: (_) => const patient.BookAppointmentScreen());
      
      case '/patient/consultation':
        final int consultationId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => patient.ConsultationScreen(consultationId: consultationId)
        );
      
      case '/patient/prescriptions':
        return MaterialPageRoute(builder: (_) => const patient.PrescriptionsScreen());
      
      case '/patient/prescription_details':
        final int prescriptionId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) =>  patient.PrescriptionDetailsScreen(prescriptionId: prescriptionId));
      
      
      case '/patient/messaging':
        return MaterialPageRoute(builder: (_) => const patient.MessagingScreen());
      
      case '/medecin/messaging':
        return MaterialPageRoute(builder: (_) => const medecin.MedecinMessagingScreen());
      
      case '/notifications':
        return MaterialPageRoute(
          builder: (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
            final userType = args?['userType'] ?? 'patient'; // Valeur par défaut
            return NotificationsScreen(userType: userType);
          }
        );

      case '/patient/first_aid':
        return MaterialPageRoute(builder: (_) => const FirstAidMenuScreen());
      
      case '/patient/first_aid/module':
        final moduleId = settings.arguments as int;
        return MaterialPageRoute(builder: (_) =>  ModuleScreen(moduleId: moduleId));
      
      // Routes pour les médecins
      case '/medecin/home':
        return MaterialPageRoute(builder: (_) => const medecin.HomeScreen());
      
      case '/medecin/appointments':
        return MaterialPageRoute(builder: (_) => const medecin.AppointmentsScreen());
      
      case '/medecin/patients':
        return MaterialPageRoute(builder: (_) => const medecin.PatientListScreen());
      
      case '/medecin/patient_details':
        final int patientId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => medecin.PatientDetailsScreen(patientId: patientId)
        );
      
      case '/medecin/consultation':
        final int consultationId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => medecin.ConsultationScreen(consultationId: consultationId)
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route non définie pour ${settings.name}'),
            ),
          ),
        );
    }
  }
}