import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/app.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/notification_service.dart';
import 'package:telesoins_plus/utils/connection_checker.dart';
import 'package:telesoins_plus/utils/logger.dart';
//import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurer la journalisation
  Logger.setLogLevel(LogLevel.info);
  Logger.i('App', 'Démarrage de l\'application TéléSoins+');
  
  try {
    // Configuration pour orienter l'app en portrait uniquement
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialisation de Firebase pour les notifications
   // await Firebase.initializeApp();
    
    // Initialisation du service de notification
    //await NotificationService().initialize();
    
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => ConnectionChecker()),
          // Ajoutez ici d'autres providers si nécessaire
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    Logger.e('App', 'Erreur lors du démarrage de l\'application', error: e, stackTrace: stackTrace);
    // Afficher un écran d'erreur ou redémarrer l'application
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Une erreur est survenue lors du démarrage de l\'application: $e'),
          ),
        ),
      ),
    );
  }
}
