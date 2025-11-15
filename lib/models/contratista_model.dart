class ContratistaModel {
  final String nombre;
  final String apellido;
  final String fechaNacimiento;
  final String email;
  final String genero;
  final String telefono;
  final String password;
  final String? fotoBase64; // Imagen en base64 (opcional)

  ContratistaModel({
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.email,
    required this.genero,
    required this.telefono,
    required this.password,
    this.fotoBase64,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'nombre': nombre,
      'apellido': apellido,
      'fechaNacimiento': fechaNacimiento,
      'email': email,
      'genero': genero,
      'telefono': telefono,
      'password': password,
    };
    
    // Solo incluir foto si existe
    if (fotoBase64 != null && fotoBase64!.isNotEmpty) {
      json['fotoBase64'] = fotoBase64;
    }
    
    return json;
  }
}


