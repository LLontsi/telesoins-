import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:telesoins_plus/config/routes.dart';
import 'package:telesoins_plus/config/theme.dart';
import 'package:telesoins_plus/screens/common/splash_screen.dart';
import 'package:telesoins_plus/services/auth_service.dart';
import 'package:telesoins_plus/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus/utils/connection_checker.dart';
import 'package:telesoins_plus/widgets/offline_banner.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final StorageService _storageService = StorageService();
  ThemeMode _themeMode = ThemeMode.light;
  Locale _locale = const Locale('fr');
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Chargement des préférences utilisateur
      final preferences = await _storageService.getUserPreferences();
      if (preferences != null) {
        setState(() {
          // Charger le thème (clair/sombre)
          final themeString = preferences['theme'] as String?;
          if (themeString == 'dark') {
            _themeMode = ThemeMode.dark;
          } else {
            _themeMode = ThemeMode.light;
          }
          
          // Charger la langue
          final languageCode = preferences['language'] as String?;
          if (languageCode != null) {
            _locale = Locale(languageCode);
          }
        });
      }
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
      print('Erreur lors du chargement des préférences: $e');
    } finally {
      // Initialiser le service d'authentification
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.initialize();
      
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si l'initialisation n'est pas terminée, afficher un écran de chargement
    if (!_isInitialized) {
      return MaterialApp(
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp(
      title: 'TéléSoins+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'), // Français
        Locale('en'), // Anglais
      ],
      locale: _locale,
      initialRoute: '/',
      onGenerateRoute: AppRouter.generateRoute,
      // Approche alternative: utiliser un Overlay pour ajouter la bannière hors-ligne
      home: Consumer<ConnectionChecker>(
        builder: (context, connectionChecker, _) {
          return Scaffold(
            body: Column(
              children: [
                // Bannière hors-ligne conditionnelle
                if (!connectionChecker.isConnected)
                  OfflineBanner(
                    onReconnect: () async {
                      final isConnected = await connectionChecker.checkConnectionWithTimeout();
                      if (!isConnected && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Aucune connexion Internet disponible'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                
                // Contenu principal de l'application
                Expanded(
                  child: Navigator(
                    initialRoute: '/',
                    onGenerateRoute: AppRouter.generateRoute,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}