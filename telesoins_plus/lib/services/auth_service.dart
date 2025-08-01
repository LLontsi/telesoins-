import 'package:flutter/foundation.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:telesoins_plus/services/api_service.dart';
import 'package:telesoins_plus/services/storage_service.dart';
import 'package:telesoins_plus/config/api_constants.dart';
import 'package:telesoins_plus/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';



class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  User? _currentUser;
  bool _isLoading = false;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isPatient => _currentUser?.userType == 'patient';
  bool get isMedecin => _currentUser?.userType == 'medecin';
  Patient? getCurrentUser() {
    // Implémentation selon votre logique de stockage d'utilisateur
    
    // Pour le développement, retournez un utilisateur fictif
    return Patient(
      id: 1,
      firstName: "Patient",
      lastName: "Test",
      email: "patient@test.com",
      phoneNumber: '+33 6 12 34 56 78',
      dateOfBirth: DateTime(1985, 5, 15),
      // Autres propriétés selon votre modèle
    );
  }
  
  // Version synchrone si besoin
  Patient? getCurrentUserSync() {
    // Pour développement
    return Patient(id: 1, firstName: "Patient", lastName: "Test",phoneNumber: '+33 6 12 34 56 78', email: "patient@test.com",);
  }
  // Initialiser le service d'authentification
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        await _getUserProfile();
      }
    } catch (e) {
      // Si une erreur se produit, déconnectons l'utilisateur
      await logout();
    } finally {
      _setLoading(false);
    }
  }
  
  // Connexion
  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _apiService.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
        requireAuth: false,
      );
      
      // Stocker les tokens
      await _storageService.setAccessToken(data['access_token']);
      await _storageService.setRefreshToken(data['refresh_token']);
      
      // Récupérer le profil de l'utilisateur
      await _getUserProfile();
    } finally {
      _setLoading(false);
    }
  }
  
  // Inscription
  Future<void> register(Map<String, dynamic> userData) async {
    _setLoading(true);
    try {
      await _apiService.post(
        ApiConstants.register,
        data: userData,
        requireAuth: false,
      );
    } finally {
      _setLoading(false);
    }
  }
  
  // Déconnexion
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _storageService.clearTokens();
      _currentUser = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Obtenir le profil utilisateur
  Future<void> _getUserProfile() async {
    try {
      final data = await _apiService.get(ApiConstants.userProfile);
      
      if (data['user_type'] == 'patient') {
        _currentUser = Patient.fromJson(data);
      } else if (data['user_type'] == 'medecin') {
        _currentUser = Medecin.fromJson(data);
      } else {
        _currentUser = User.fromJson(data);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    _setLoading(true);
    try {
      final data = await _apiService.put(
        ApiConstants.updateProfile,
        data: userData,
      );
      
      if (_currentUser?.userType == 'patient') {
        _currentUser = Patient.fromJson(data);
      } else if (_currentUser?.userType == 'medecin') {
        _currentUser = Medecin.fromJson(data);
      } else {
        _currentUser = User.fromJson(data);
      }
      
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Rafraîchir le token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }
      
      final data = await _apiService.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
        requireAuth: false,
      );
      
      await _storageService.setAccessToken(data['access_token']);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}