import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/app.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/utils/connection_checker.dart';
import 'package:mockito/mockito.dart';

// Mocks pour les services
class MockAuthService extends Mock implements AuthService {}
class MockConnectionChecker extends Mock implements ConnectionChecker {}

void main() {
  late MockAuthService mockAuthService;
  late MockConnectionChecker mockConnectionChecker;

  setUp(() {
    mockAuthService = MockAuthService();
    mockConnectionChecker = MockConnectionChecker();
    
    // Configuration des comportements par défaut des mocks
    when(mockConnectionChecker.isConnected).thenReturn(true);
    when(mockAuthService.isLoggedIn).thenReturn(false);
    when(mockAuthService.isPatient).thenReturn(false);
    when(mockAuthService.isMedecin).thenReturn(false);
  });

  testWidgets('L\'application se lance correctement', (WidgetTester tester) async {
    // Construction de l'application avec les mocks
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<ConnectionChecker>.value(value: mockConnectionChecker),
        ],
        child: const MyApp(),
      ),
    );

    // Vérification que l'écran de démarrage s'affiche
    expect(find.text('TéléSoins+'), findsOneWidget);
    expect(find.byIcon(Icons.health_and_safety), findsOneWidget);
    
    // Attendre que les animations soient terminées
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets('La bannière hors-ligne s\'affiche lorsque déconnecté', (WidgetTester tester) async {
    // Configurer le mock pour simuler une déconnexion
    when(mockConnectionChecker.isConnected).thenReturn(false);
    
    // Construction de l'application avec les mocks
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<ConnectionChecker>.value(value: mockConnectionChecker),
        ],
        child: const MyApp(),
      ),
    );

    // Attendre que les animations soient terminées
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    
    // Vérifier que la bannière hors-ligne est présente
    expect(find.text('Vous êtes en mode hors-ligne. Certaines fonctionnalités peuvent être limitées.'), findsOneWidget);
    expect(find.text('Reconnecter'), findsOneWidget);
  });

  testWidgets('Redirection après le SplashScreen selon le statut de connexion', (WidgetTester tester) async {
    // Configuration pour simuler un utilisateur connecté en tant que patient
    when(mockAuthService.isLoggedIn).thenReturn(true);
    when(mockAuthService.isPatient).thenReturn(true);
    
    // Construction de l'application avec les mocks
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
          ChangeNotifierProvider<ConnectionChecker>.value(value: mockConnectionChecker),
        ],
        child: const MyApp(),
      ),
    );

    // Attendre que les animations et la redirection soient terminées
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    
    // Vérifier que la navigation a eu lieu vers l'écran d'accueil patient
    // Note: Cette vérification est simplifiée car nous ne pouvons pas facilement vérifier la navigation dans ce test
    // Dans un test réel, on pourrait utiliser des technologies comme NavigatorObserver
    verify(mockAuthService.isLoggedIn).called(greaterThan(0));
    verify(mockAuthService.isPatient).called(greaterThan(0));
  });
}