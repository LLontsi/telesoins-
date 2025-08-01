import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:telesoins_plus2/config/routes.dart';
import 'package:telesoins_plus2/config/theme.dart';
import 'package:telesoins_plus2/services/auth_service.dart';
import 'package:telesoins_plus2/main.dart';

class TeleSoinsApp extends StatelessWidget {
  const TeleSoinsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = getIt<AuthService>();
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          final router = createRouter(authService);
          
          return MaterialApp.router(
            title: 'TéléSoins+',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            locale: const Locale('fr'),
          );
        },
      ),
    );
  }
}