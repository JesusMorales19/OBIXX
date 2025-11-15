class TrabajadorModel {
  final String nombre;
  final String apellido;
  final String fechaNacimiento;
  final String email;
  final String genero;
  final String telefono;
  final int experiencia;
  final String categoria;
  final String password;
  final String? fotoBase64; // Imagen en base64 (opcional)

  TrabajadorModel({
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.email,
    required this.genero,
    required this.telefono,
    required this.experiencia,
    required this.categoria,
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
      'experiencia': experiencia,
      'categoria': categoria,
      'password': password,
    };
    
    // Solo incluir foto si existe
    if (fotoBase64 != null && fotoBase64!.isNotEmpty) {
      json['fotoBase64'] = fotoBase64;
    }
    
    return json;
  }
}


