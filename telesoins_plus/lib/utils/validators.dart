class Validators {
  // Validateur d'adresse e-mail
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer une adresse e-mail';
    }
    
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Veuillez entrer une adresse e-mail valide';
    }
    
    return null;
  }
  
  // Validateur de mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un mot de passe';
    }
    
    if (value.length < 8) {
      return 'Le mot de passe doit comporter au moins 8 caractères';
    }
    
    return null;
  }
  
  // Validateur de numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un numéro de téléphone';
    }
    
    final phoneRegExp = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'\s+'), ''))) {
      return 'Veuillez entrer un numéro de téléphone valide';
    }
    
    return null;
  }
  
  // Validateur de texte obligatoire
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire${fieldName != null ? ' : $fieldName' : ''}';
    }
    
    return null;
  }
  
  // Validateur de date
  static String? validateDate(DateTime? value) {
    if (value == null) {
      return 'Veuillez sélectionner une date';
    }
    
    return null;
  }
}