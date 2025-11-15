/// Servicio centralizado para validaciones de formularios
class ValidationService {
  /// Valida si un email tiene formato válido
  static bool isValidEmail(String email) {
    if (email.trim().isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Valida si un teléfono tiene formato válido (10 dígitos)
  static bool isValidPhone(String phone) {
    if (phone.trim().isEmpty) return false;
    final phoneRegex = RegExp(r'^[0-9]{10}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s-]'), ''));
  }

  /// Valida si una fecha tiene formato válido (DD/MM/YYYY o YYYY-MM-DD)
  static bool isValidDate(String date) {
    if (date.trim().isEmpty) return false;
    final dateRegex = RegExp(r'^\d{2}/\d{2}/\d{4}$|^\d{4}-\d{2}-\d{2}$');
    return dateRegex.hasMatch(date.trim());
  }

  /// Valida si una contraseña cumple con los requisitos:
  /// - Mínimo 8 caracteres
  /// - Al menos una mayúscula
  /// - Al menos una minúscula
  /// - Al menos un número
  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false; // Al menos una mayúscula
    if (!password.contains(RegExp(r'[a-z]'))) return false; // Al menos una minúscula
    if (!password.contains(RegExp(r'[0-9]'))) return false; // Al menos un número
    return true;
  }

  /// Valida si un número de experiencia es válido (0-100)
  static bool isValidExperience(String experience) {
    final exp = int.tryParse(experience);
    return exp != null && exp >= 0 && exp <= 100;
  }

  /// Valida si un nombre/apellido es válido (mínimo 2 caracteres)
  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length >= 2;
  }

  /// Obtiene el mensaje de error para un email inválido
  static String? getEmailError(String email) {
    if (email.trim().isEmpty) {
      return 'El correo es requerido';
    }
    if (!isValidEmail(email)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  /// Obtiene el mensaje de error para un teléfono inválido
  static String? getPhoneError(String phone) {
    if (phone.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    if (!isValidPhone(phone)) {
      return 'Ingresa un teléfono válido (10 dígitos)';
    }
    return null;
  }

  /// Obtiene el mensaje de error para una fecha inválida
  static String? getDateError(String date) {
    if (date.trim().isEmpty) {
      return 'La fecha es requerida';
    }
    if (!isValidDate(date)) {
      return 'Formato de fecha inválido (DD/MM/YYYY)';
    }
    return null;
  }

  /// Obtiene el mensaje de error para una contraseña inválida
  static String? getPasswordError(String password) {
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener más de 8 caracteres';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La contraseña debe contener al menos una mayúscula';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'La contraseña debe contener al menos una minúscula';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  /// Obtiene el mensaje de error para un nombre/apellido inválido
  static String? getNameError(String name, {String fieldName = 'El nombre'}) {
    if (name.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    if (name.trim().length < 2) {
      return '$fieldName debe tener al menos 2 caracteres';
    }
    return null;
  }
}

