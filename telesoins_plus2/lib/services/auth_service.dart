import 'package:flutter/material.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/models/user.dart';
import 'package:telesoins_plus2/services/api_service.dart';
import 'package:telesoins_plus2/services/storage_service.dart';


class AuthService extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;
  
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  
  AuthService({
    required ApiService apiService,
    required StorageService storageService,
  }) : _apiService = apiService, _storageService = storageService {
    // Charger le token et les informations utilisateur au démarrage
    _loadAuthData();
  }
  
  // Getters
  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String get userRole => _currentUser?.role ?? '';
  
  // Chargement des données d'authentification
  Future<void> _loadAuthData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _token = await _storageService.getToken();
      final userData = await _storageService.getUserData();
      
      if (_token != null && userData != null) {
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      print('Erreur lors du chargement des données d\'authentification: $e');
      // En cas d'erreur, effacer les données
      await _storageService.clearAll();
      _token = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Connexion
  Future<User> login(String email, String password) async {
  _isLoading = true;
  notifyListeners();

  try {
    print('🔍 Mode développement: ${ApiConstants.isDevMode}');
    print('🌍 Connexion à ${ApiConstants.login}');

    final response = await _apiService.post(
      ApiConstants.login,
      data: {
        'username': email, 
        'password': password,
      },
    );

    print('✅ Réponse API: $response');

    _token = response['token'];
    await _storageService.saveToken(_token!);

    final userData = await _apiService.get(ApiConstants.userProfile);
    print('👤 Utilisateur connecté: $userData');

    _currentUser = User.fromJson(userData);
    await _storageService.saveUserData(_currentUser!.toJson());

    return _currentUser!;
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // Inscription
  Future<User> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
       await _apiService.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'password2': password,  // Confirmation du mot de passe
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'phone_number': phoneNumber,
        },
      );
      
      // Après l'inscription, connecter l'utilisateur
      return await login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Déconnexion
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _storageService.clearAll();
      _token = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Mise à jour du profil
  Future<User> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    // Autres champs à mettre à jour
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final data = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };
      
      final response = await _apiService.put(
        ApiConstants.userProfile,
        data: data,
      );
      
      _currentUser = User.fromJson(response);
      await _storageService.saveUserData(_currentUser!.toJson());
      
      return _currentUser!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}