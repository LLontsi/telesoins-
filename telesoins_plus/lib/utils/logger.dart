enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  fatal
}

class Logger {
  static LogLevel _currentLevel = LogLevel.info;
  static bool _enableConsoleOutput = true;
  
  // Configurer le niveau de journalisation
  static void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }
  
  // Activer/désactiver la sortie console
  static void enableConsoleOutput(bool enable) {
    _enableConsoleOutput = enable;
  }
  
  // Journalisation détaillée
  static void v(String tag, String message) {
    _log(LogLevel.verbose, tag, message);
  }
  
  // Journalisation de débogage
  static void d(String tag, String message) {
    _log(LogLevel.debug, tag, message);
  }
  
  // Journalisation d'information
  static void i(String tag, String message) {
    _log(LogLevel.info, tag, message);
  }
  
  // Journalisation d'avertissement
  static void w(String tag, String message) {
    _log(LogLevel.warning, tag, message);
  }
  
  // Journalisation d'erreur
  static void e(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, tag, message, error: error, stackTrace: stackTrace);
  }
  
  // Journalisation d'erreur fatale
  static void f(String tag, String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, tag, message, error: error, stackTrace: stackTrace);
  }
  
  // Méthode principale de journalisation
  static void _log(LogLevel level, String tag, String message, {Object? error, StackTrace? stackTrace}) {
    if (level.index < _currentLevel.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] $levelStr/$tag: $message';
    
    if (_enableConsoleOutput) {
      print(logMessage);
      
      if (error != null) {
        print('ERROR: $error');
      }
      
      if (stackTrace != null) {
        print('STACK TRACE: $stackTrace');
      }
    }
    
    // Ici, vous pourriez implémenter d'autres mécanismes de journalisation
    // comme l'envoi à un service distant ou l'enregistrement dans un fichier
  }
}