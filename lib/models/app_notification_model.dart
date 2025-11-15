import 'dart:convert';

class AppNotificationModel {
  final int id;
  final String titulo;
  final String cuerpo;
  final DateTime createdAt;
  final bool leida;
  final Map<String, dynamic> data;

  AppNotificationModel({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.createdAt,
    required this.leida,
    required this.data,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic> parsedData;
    if (rawData is Map<String, dynamic>) {
      parsedData = Map<String, dynamic>.from(rawData);
    } else if (rawData is String) {
      try {
        parsedData = Map<String, dynamic>.from(jsonDecode(rawData));
      } catch (_) {
        parsedData = {'mensaje': rawData};
      }
    } else {
      parsedData = {};
    }

    return AppNotificationModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      titulo: json['titulo']?.toString() ?? 'Notificación',
      cuerpo: json['cuerpo']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt'] ?? json['fechaCreacion']),
      leida: json['leida'] == true,
      data: parsedData,
    );
  }

  AppNotificationModel copyWith({
    int? id,
    String? titulo,
    String? cuerpo,
    DateTime? createdAt,
    bool? leida,
    Map<String, dynamic>? data,
  }) {
    return AppNotificationModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      cuerpo: cuerpo ?? this.cuerpo,
      createdAt: createdAt ?? this.createdAt,
      leida: leida ?? this.leida,
      data: data ?? Map<String, dynamic>.from(this.data),
    );
  }

  String get formattedDate {
    final twoDigits = (int n) => n.toString().padLeft(2, '0');
    return '${createdAt.year}-${twoDigits(createdAt.month)}-${twoDigits(createdAt.day)} '
        '${twoDigits(createdAt.hour)}:${twoDigits(createdAt.minute)}';
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}
