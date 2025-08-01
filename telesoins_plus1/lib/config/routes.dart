//import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:telesoins_plus/screens/common/login_screen.dart';
import 'package:telesoins_plus/screens/common/signup_screen.dart';
import 'package:telesoins_plus/screens/common/profile_screen.dart';
import 'package:telesoins_plus/screens/patient/home_screen.dart';
import 'package:telesoins_plus/screens/patient/appointments_screen.dart';
import 'package:telesoins_plus/screens/patient/book_appointment_screen.dart';
import 'package:telesoins_plus/screens/patient/consultation_screen.dart';
import 'package:telesoins_plus/screens/patient/messaging_screen.dart';
import 'package:telesoins_plus/screens/patient/prescriptions_screen.dart';
import 'package:telesoins_plus/screens/patient/first_aid/first_aid_menu.dart';
import 'package:telesoins_plus/screens/patient/first_aid/module_screen.dart';
/*import 'package:telesoins_plus/screens/patient/first_aid/quiz_screen.dart';
import 'package:telesoins_plus/screens/medecin/home_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/appointments_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/patient_list_screen.dart';
import 'package:telesoins_plus/screens/medecin/patient_details_screen.dart';
import 'package:telesoins_plus/screens/medecin/consultation_screen.dart' as medecin;
import 'package:telesoins_plus/screens/medecin/prescription_editor.dart';*/
import 'package:telesoins_plus/services/auth_service.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSignupRoute = state.matchedLocation == '/signup';
      
      // Si l'utilisateur n'est pas connecté et n'est pas sur la page de connexion/inscription,
      // rediriger vers la page de connexion
      if (!isLoggedIn && !isLoginRoute && !isSignupRoute) {
        return '/login';
      }
      
      // Si l'utilisateur est connecté et est sur la page de connexion/inscription,
      // rediriger vers la page d'accueil en fonction du rôle
      if (isLoggedIn && (isLoginRoute || isSignupRoute)) {
        if (authService.userRole == 'patient') {
          return '/patient/home';
        } else if (authService.userRole == 'medecin') {
          return '/medecin/home';
        }
      }
      
      return null;
    },
    routes: [
      // Routes d'authentification
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      
      // Routes communes
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // Routes spécifiques aux patients
      GoRoute(
        path: '/patient/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/patient/appointments',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/patient/book-appointment',
        builder: (context, state) => const BookAppointmentScreen(),
      ),
      GoRoute(
        path: '/patient/consultation/:id',
        builder: (context, state) => ConsultationScreen(
          consultationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/patient/messaging/:id',
        builder: (context, state) => MessagingScreen(
          consultationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/patient/prescriptions',
        builder: (context, state) => const PrescriptionsScreen(),
      ),
      GoRoute(
        path: '/patient/first-aid',
        builder: (context, state) => const FirstAidMenuScreen(),
      ),
      GoRoute(
        path: '/patient/first-aid/module/:id',
        builder: (context, state) => ModuleScreen(
          moduleId: state.pathParameters['id']!,
        ),
      ),
      /*GoRoute(
        path: '/patient/first-aid/quiz/:id',
        builder: (context, state) => QuizScreen(
          quizId: state.pathParameters['id']!,
        ),
      ),
      
      // Routes spécifiques aux médecins
      GoRoute(
        path: '/medecin/home',
        builder: (context, state) => const medecin.HomeScreen(),
      ),
      GoRoute(
        path: '/medecin/appointments',
        builder: (context, state) => const medecin.AppointmentsScreen(),
      ),
      GoRoute(
        path: '/medecin/patients',
        builder: (context, state) => const PatientListScreen(),
      ),
      GoRoute(
        path: '/medecin/patient/:id',
        builder: (context, state) => PatientDetailsScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/medecin/consultation/:id',
        builder: (context, state) => medecin.ConsultationScreen(
          consultationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/medecin/prescription/edit/:consultationId',
        builder: (context, state) => PrescriptionEditorScreen(
          consultationId: state.pathParameters['consultationId']!,
        ),
      ),*/
    ],
  );
}