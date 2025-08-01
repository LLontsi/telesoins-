import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telesoins_plus2/app.dart';
import 'package:telesoins_plus2/services/auth_service.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/services/storage_service.dart';
import 'package:get_it/get_it.dart';

void main() {
  // Registering the necessary services
  setUp(() async {
    final getIt = GetIt.instance;

    // Registering mock services or real services
    getIt.registerSingleton<StorageService>(StorageService());
    getIt.registerSingleton<ApiService>(ApiService());
    getIt.registerSingleton<AuthService>(AuthService(
      apiService: getIt<ApiService>(),
      storageService: getIt<StorageService>(),
    ));

    // Initialize other services if needed
    await getIt.allReady();
  });

  testWidgets('TeleSoinsApp loads correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const TeleSoinsApp());

    // Check if the app is rendered correctly (modify this based on your app's UI)
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('TeleSoinsApp'), findsOneWidget); // Modify this as per your UI

    // You can now continue with more widget tests, e.g., tapping a button, verifying text, etc.
  });
}