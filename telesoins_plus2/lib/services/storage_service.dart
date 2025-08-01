import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  
  late SharedPreferences _prefs;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Gestion du token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }
  
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }
  
  // Gestion des données utilisateur
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _prefs.setString(_userDataKey, jsonEncode(userData));
  }
  
  Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = _prefs.getString(_userDataKey);
    if (userDataString != null) {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    }
    return null;
  }
  
  // Gestion des données offline
  Future<void> saveOfflineData(String key, dynamic data) async {
    await _prefs.setString(key, jsonEncode(data));
  }
  
  Future<dynamic> getOfflineData(String key) async {
    final dataString = _prefs.getString(key);
    if (dataString != null) {
      return jsonDecode(dataString);
    }
    return null;
  }
  
  // Effacer toutes les données
  Future<void> clearAll() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userDataKey);
  }
}