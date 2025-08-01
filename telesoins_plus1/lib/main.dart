import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:telesoins_plus/app.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/api_service.dart';
import 'package:telesoins_plus/services/storage_service.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importation correcte pour initializeDateFormatting


final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('fr_FR');
  // Orientation portrait uniquement
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialiser les services
  await _setupServices();
  
  runApp(const TeleSoinsApp());
}

Future<void> _setupServices() async {
  // Initialiser le service de stockage
  final storageService = StorageService();
  await storageService.init();
  getIt.registerSingleton<StorageService>(storageService);
  
  // Initialiser le service API
  final apiService = ApiService();
  getIt.registerSingleton<ApiService>(apiService);
  
  // Initialiser le service d'authentification
  final authService = AuthService(
    apiService: apiService,
    storageService: storageService,
  );
  getIt.registerSingleton<AuthService>(authService);
}