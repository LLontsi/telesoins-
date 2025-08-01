//import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:telesoins_plus2/config/api_constants.dart';
import 'package:telesoins_plus2/services/storage_service.dart';
import 'package:telesoins_plus2/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/first_aid.dart';

class ApiService {
  late Dio _dio;
  final StorageService _storageService = getIt<StorageService>();
  
  ApiService() {
    _dio = Dio();
    _setupDio();
  }

  
  
  void _setupDio() {
    _dio.options.baseUrl = ApiConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Intercepteur pour ajouter le token d'authentification
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Token $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expiré ou invalide, déconnecter l'utilisateur
          _storageService.clearAll();
          // Ici, vous pourriez notifier un système d'événements pour rediriger vers la page de connexion
        }
        return handler.next(error);
      },
    ));
  }
  
  // Méthodes génériques pour les requêtes HTTP
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<dynamic> post(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<dynamic> put(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<dynamic> patch(String endpoint, {dynamic data}) async {
    try {
      final response = await _dio.patch(
        endpoint,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(endpoint);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  Future<bool> testConnection() async {
  try {
    print('Test de connexion à ${_dio.options.baseUrl}');
    
    final options = Options(
      method: 'GET',
      validateStatus: (status) => true, // Accepter tous les codes de statut
    );
    
    final response = await _dio.request(
      '',  // Chemin vide pour tester juste la connexion de base
      options: options,
    );
    
    print('Code de statut de la réponse: ${response.statusCode}');
    return response.statusCode != null;
  } catch (e) {
    print('Erreur de test de connexion: $e');
    return false;
  }
}
  // Upload de fichiers
  Future<dynamic> uploadFile(String endpoint, File file, {Map<String, dynamic>? data}) async {
    try {
      String fileName = file.path.split('/').last;
      FormData formData = FormData.fromMap({
        ...?data,
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });
      
      final response = await _dio.post(
        endpoint,
        data: formData,
      );
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  void _handleError(DioException error) {
    if (error.response != null) {
      print('Erreur API: ${error.response!.statusCode} - ${error.response!.data}');
    } else {
      print('Erreur API: ${error.message}');
    }
  }
}

class QuizService {
  final String baseUrl;
  final String token;

  QuizService({required this.baseUrl, required this.token});

  Future<List<Quiz>> getQuizzesByModule(int moduleId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/by_module/?module_id=$moduleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Quiz.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement des quiz');
    }
  }

  Future<List<QuizQuestion>> getQuizQuestions(int quizId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/quizzes/$quizId/questions/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => QuizQuestion.fromJson(json)).toList();
    } else {
      throw Exception('Échec du chargement des questions');
    }
  }

  Future<QuizResult> submitQuizAnswers(int quizId, Map<String, String> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/quizzes/$quizId/submit/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'answers': answers}),
    );

    if (response.statusCode == 200) {
      return QuizResult.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec de la soumission du quiz');
    }
  }
}