import 'package:intl/intl.dart';

/// Servicio centralizado para formateo de datos
class FormatService {
  /// Formatea un número a string con 2 decimales
  /// Maneja null, String, int, double
  static String formatNumber(dynamic value) {
    if (value == null) return '0.00';
    try {
      final numero = value is String 
          ? double.tryParse(value) ?? 0.0
          : value is int 
              ? value.toDouble()
              : value is double 
                  ? value 
                  : 0.0;
      return numero.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  /// Formatea un número como moneda (con símbolo $)
  static String formatCurrency(dynamic value, {String currency = 'MXN'}) {
    final formatted = formatNumber(value);
    return '\$$formatted $currency';
  }

  /// Formatea una fecha a formato DD/MM/YYYY
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formatea una fecha a formato YYYY-MM-DD (para APIs)
  static String formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Formatea una fecha desde string (acepta múltiples formatos)
  static String formatDateFromString(String dateString) {
    try {
      // Intentar parsear diferentes formatos
      DateTime? date;
      
      // Formato YYYY-MM-DD
      if (dateString.contains('-') && dateString.length == 10) {
        date = DateTime.tryParse(dateString.split('T')[0]);
      }
      // Formato DD/MM/YYYY
      else if (dateString.contains('/') && dateString.length == 10) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          date = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }
      
      if (date != null) {
        return formatDate(date);
      }
      
      // Si no se puede parsear, intentar parsear directamente
      final parsed = DateTime.tryParse(dateString.split('T')[0]);
      if (parsed != null) {
        return formatDate(parsed);
      }
      
      // Si todo falla, devolver el string original sin la parte de tiempo
      return dateString.split('T')[0];
    } catch (e) {
      // Si falla, devolver el string original sin la parte de tiempo
      return dateString.split('T')[0];
    }
  }

  /// Formatea un presupuesto (número grande)
  static String formatPresupuesto(dynamic value) {
    if (value == null) return '0.00';
    try {
      final numero = value is String 
          ? double.tryParse(value) ?? 0.0
          : value is int 
              ? value.toDouble()
              : value is double 
                  ? value 
                  : 0.0;
      
      // Si es un número grande, usar separador de miles
      if (numero >= 1000) {
        final formatter = NumberFormat('#,###.00');
        return formatter.format(numero);
      }
      
      return numero.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  /// Formatea horas trabajadas
  static String formatHoras(double horas) {
    if (horas == 0) return '0.00';
    return horas.toStringAsFixed(2);
  }

  /// Formatea un timestamp a fecha legible
  static String formatTimestamp(DateTime timestamp) {
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
  }

  /// Parsea un valor dinámico a double (nullable)
  static double? parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  /// Parsea un valor dinámico a double (no nullable, retorna 0.0 si falla)
  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  /// Parsea un valor dinámico a int (no nullable, retorna 0 si falla)
  static int parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Formatea fecha desde string ISO (extrae solo YYYY-MM-DD)
  static String formatDateFromIsoString(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'No especificada';
    try {
      // Si viene en formato ISO (2025-01-15T06:00:00.000Z), extraer solo la fecha
      if (dateString.contains('T')) {
        return dateString.split('T')[0];
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  /// Formatea fecha desde string a DD/MM/YYYY (para mostrar)
  static String formatDateStringForDisplay(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'No especificada';
    try {
      // Primero extraer solo la fecha si viene en formato ISO
      final fechaLimpia = dateString.contains('T') ? dateString.split('T')[0] : dateString;
      final date = DateTime.tryParse(fechaLimpia);
      if (date != null) {
        return formatDate(date);
      }
      return fechaLimpia;
    } catch (e) {
      return dateString.contains('T') ? dateString.split('T')[0] : dateString;
    }
  }
}

