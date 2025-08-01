import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Clés de stockage sécurisé
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  
  // Clés de stockage standard
  static const String userPreferencesKey = 'user_preferences';
  static const String offlineDataKey = 'offline_data';
  static const String firstAidContentKey = 'first_aid_content';
  
  // Méthodes pour le stockage sécurisé des tokens
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: accessTokenKey, value: token);
  }
  
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: accessTokenKey);
  }
  
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: refreshTokenKey, value: token);
  }
  
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: refreshTokenKey);
  }
  
  Future<void> clearTokens() async {
    await _secureStorage.delete(key: accessTokenKey);
    await _secureStorage.delete(key: refreshTokenKey);
  }
  
  // Méthodes pour les préférences utilisateur
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userPreferencesKey, preferences.toString());
  }
  
  Future<Map<String, dynamic>?> getUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final prefString = prefs.getString(userPreferencesKey);
    if (prefString == null) return null;
    
    try {
      // Convertir la chaîne en Map (à adapter si vous utilisez un encodage différent)
      // Note: Ceci est une implémentation simplifiée, vous devriez utiliser JSON dans un cas réel
      final Map<String, dynamic> prefMap = {};
      // Logique de conversion de chaîne en Map
      return prefMap;
    } catch (e) {
      return null;
    }
  }
  
  // Méthodes pour les données hors-ligne
  Future<void> saveOfflineData(String key, String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$offlineDataKey.$key', data);
  }
  
  Future<String?> getOfflineData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$offlineDataKey.$key');
  }
  
  Future<void> removeOfflineData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$offlineDataKey.$key');
  }
  
  // Gestion du contenu de premiers secours
  Future<void> saveFirstAidContent(String moduleId, String content) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$firstAidContentKey.$moduleId', content);
  }
  
  Future<String?> getFirstAidContent(String moduleId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$firstAidContentKey.$moduleId');
  }
  
  Future<List<String>> getAllSavedFirstAidModules() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys
        .where((key) => key.startsWith(firstAidContentKey))
        .map((key) => key.replaceFirst('$firstAidContentKey.', ''))
        .toList();
  }
  
  Future<void> clearFirstAidContent() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(firstAidContentKey)) {
        await prefs.remove(key);
      }
    }
  }
}