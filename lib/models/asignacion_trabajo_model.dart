class AsignacionTrabajoModel {
  final String emailContratista;
  final String emailTrabajador;
  final String tipoTrabajo; // 'corto' o 'largo'
  final int idTrabajo;
  final int? idSolicitud;

  // Campos opcionales que pueden venir en la respuesta
  final String? estado;
  final DateTime? fechaAsignacion;
  final int? vacantesRestantes;
  final String? estadoTrabajo;

  const AsignacionTrabajoModel({
    required this.emailContratista,
    required this.emailTrabajador,
    required this.tipoTrabajo,
    required this.idTrabajo,
    this.idSolicitud,
    this.estado,
    this.fechaAsignacion,
    this.vacantesRestantes,
    this.estadoTrabajo,
  });

  factory AsignacionTrabajoModel.fromJson(Map<String, dynamic> json) {
    return AsignacionTrabajoModel(
      emailContratista: json['email_contratista'] ?? json['emailContratista'] ?? '',
      emailTrabajador: json['email_trabajador'] ?? json['emailTrabajador'] ?? '',
      tipoTrabajo: json['tipo_trabajo'] ?? json['tipoTrabajo'] ?? '',
      idTrabajo: int.tryParse((json['id_trabajo'] ?? json['idTrabajo']).toString()) ?? 0,
      idSolicitud: json['id_solicitud'] != null
          ? int.tryParse(json['id_solicitud'].toString())
          : (json['idSolicitud'] != null
              ? int.tryParse(json['idSolicitud'].toString())
              : null),
      estado: json['estado'],
      fechaAsignacion: json['fecha_asignacion'] != null
          ? DateTime.tryParse(json['fecha_asignacion'].toString())
          : null,
      vacantesRestantes: json['vacantesRestantes'] != null
          ? int.tryParse(json['vacantesRestantes'].toString())
          : null,
      estadoTrabajo: json['estadoTrabajo'],
    );
  }

  Map<String, dynamic> toJsonForCreate() {
    return {
      'emailContratista': emailContratista,
      'emailTrabajador': emailTrabajador,
      'tipoTrabajo': tipoTrabajo,
      'idTrabajo': idTrabajo,
      if (idSolicitud != null) 'idSolicitud': idSolicitud,
    };
  }

  AsignacionTrabajoModel copyWith({
    String? emailContratista,
    String? emailTrabajador,
    String? tipoTrabajo,
    int? idTrabajo,
    int? idSolicitud,
    String? estado,
    DateTime? fechaAsignacion,
    int? vacantesRestantes,
    String? estadoTrabajo,
  }) {
    return AsignacionTrabajoModel(
      emailContratista: emailContratista ?? this.emailContratista,
      emailTrabajador: emailTrabajador ?? this.emailTrabajador,
      tipoTrabajo: tipoTrabajo ?? this.tipoTrabajo,
      idTrabajo: idTrabajo ?? this.idTrabajo,
      idSolicitud: idSolicitud ?? this.idSolicitud,
      estado: estado ?? this.estado,
      fechaAsignacion: fechaAsignacion ?? this.fechaAsignacion,
      vacantesRestantes: vacantesRestantes ?? this.vacantesRestantes,
      estadoTrabajo: estadoTrabajo ?? this.estadoTrabajo,
    );
  }
}
