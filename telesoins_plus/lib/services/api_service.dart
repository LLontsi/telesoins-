import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:telesoins_plus/config/api_constants.dart';
import 'package:telesoins_plus/services/storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();
  final http.Client _client = http.Client();
  
  // En-têtes communs pour toutes les requêtes
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (requireAuth) {
      final token = await _storageService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Méthode GET
  Future<dynamic> get(String endpoint, {bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _client
          .get(Uri.parse(ApiConstants.baseUrl + endpoint), headers: headers)
          .timeout(Duration(milliseconds: ApiConstants.connectionTimeout));
      
      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException('Pas de connexion Internet');
    } on http.ClientException {
      throw ApiException('Erreur de connexion au serveur');
    } on TimeoutException {
      throw ApiException('La requête a pris trop de temps');
    }
  }
  
  // Méthode POST
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data, bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _client
          .post(
            Uri.parse(ApiConstants.baseUrl + endpoint),
            headers: headers,
            body: data != null ? json.encode(data) : null,
          )
          .timeout(Duration(milliseconds: ApiConstants.connectionTimeout));
      
      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException('Pas de connexion Internet');
    } on http.ClientException {
      throw ApiException('Erreur de connexion au serveur');
    } on TimeoutException {
      throw ApiException('La requête a pris trop de temps');
    }
  }
  
  // Méthode PUT
  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data, bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _client
          .put(
            Uri.parse(ApiConstants.baseUrl + endpoint),
            headers: headers,
            body: data != null ? json.encode(data) : null,
          )
          .timeout(Duration(milliseconds: ApiConstants.connectionTimeout));
      
      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException('Pas de connexion Internet');
    } on http.ClientException {
      throw ApiException('Erreur de connexion au serveur');
    } on TimeoutException {
      throw ApiException('La requête a pris trop de temps');
    }
  }
  
  // Méthode DELETE
  Future<dynamic> delete(String endpoint, {bool requireAuth = true}) async {
    try {
      final headers = await _getHeaders(requireAuth: requireAuth);
      final response = await _client
          .delete(Uri.parse(ApiConstants.baseUrl + endpoint), headers: headers)
          .timeout(Duration(milliseconds: ApiConstants.connectionTimeout));
      
      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException('Pas de connexion Internet');
    } on http.ClientException {
      throw ApiException('Erreur de connexion au serveur');
    } on TimeoutException {
      throw ApiException('La requête a pris trop de temps');
    }
  }
  
  // Méthode pour uploader des fichiers
  Future<dynamic> uploadFile(String endpoint, File file, String fileField, {Map<String, String>? fields, bool requireAuth = true}) async {
    try {
      final token = requireAuth ? await _storageService.getAccessToken() : null;
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.baseUrl + endpoint),
      );
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(fileField, file.path));
      
      if (fields != null) {
        request.fields.addAll(fields);
      }
      
      final streamedResponse = await request.send()
          .timeout(Duration(milliseconds: ApiConstants.connectionTimeout));
      
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } on SocketException {
      throw NoConnectionException('Pas de connexion Internet');
    } on http.ClientException {
      throw ApiException('Erreur de connexion au serveur');
    } on TimeoutException {
      throw ApiException('La requête a pris trop de temps');
    }
  }
  
  // Gestion des réponses HTTP
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    } else if (statusCode == 401) {
      throw UnauthorizedException('Non autorisé. Veuillez vous reconnecter.');
    } else if (statusCode >= 400 && statusCode < 500) {
      throw ClientException('Erreur de requête: ${response.body}');
    } else if (statusCode >= 500) {
      throw ServerException('Erreur serveur. Veuillez réessayer plus tard.');
    } else {
      throw ApiException('Erreur inconnue: ${response.body}');
    }
  }
}

// Exceptions personnalisées pour la gestion d'erreur
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class NoConnectionException extends ApiException {
  NoConnectionException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ClientException extends ApiException {
  ClientException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}

class TimeoutException extends ApiException {
  TimeoutException(String message) : super(message);
}