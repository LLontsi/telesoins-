import 'package:intl/intl.dart';

class DateFormatter {
  // Format standard pour la date (jour mois année)
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    
    return DateFormat.yMMMMd('fr').format(date);
  }
  
  // Format pour l'heure (heure:minutes)
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    
    return DateFormat.Hm('fr').format(date);
  }
  
  // Format pour la date et l'heure
  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    
    return '${formatDate(date)} à ${formatTime(date)}';
  }
  
  // Format relatif (aujourd'hui, hier, demain, etc.)
  static String formatRelativeDate(DateTime? date) {
    if (date == null) return '';
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Aujourd\'hui à ${formatTime(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Hier à ${formatTime(date)}';
    } else if (dateToCheck == tomorrow) {
      return 'Demain à ${formatTime(date)}';
    } else {
      return formatDateTime(date);
    }
  }
  
  // Calcul de l'âge à partir de la date de naissance
  static int calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }
}