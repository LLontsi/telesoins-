import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FileUtils {
  // Obtenir le répertoire temporaire
  static Future<Directory> getTemporaryDirectory() async {
    return await getTemporaryDirectory();
  }
  
  // Obtenir le répertoire d'application
  static Future<Directory> getApplicationDirectory() async {
    return await getApplicationDocumentsDirectory();
  }
  
  // Télécharger un fichier à partir d'une URL
  static Future<File> downloadFile(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    
    final file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    
    return file;
  }
  
  // Vérifier si un fichier existe
  static Future<bool> fileExists(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    
    return File(filePath).exists();
  }
  
  // Supprimer un fichier
  static Future<void> deleteFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$filename';
    
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  // Obtenir la taille d'un fichier en Mo
  static Future<double> getFileSize(File file) async {
    final bytes = await file.length();
    return bytes / (1024 * 1024); // Convertir octets en Mo
  }
  
  // Formater la taille d'un fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }
}