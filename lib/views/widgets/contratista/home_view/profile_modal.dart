import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:integradora/services/api_service.dart';
import 'package:integradora/services/storage_service.dart';
import 'package:integradora/services/format_service.dart';
import 'package:integradora/views/widgets/custom_notification.dart';
import 'review_card.dart';

void showProfileModal(
  BuildContext context,
  String name,
  int edad,
  String categoria,
  String descripcion,
  String image,
  double rating,
  int experiencia,
  String status,
  Color statusColor,
  String emailTrabajador,
  String telefono,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: _ProfileContent(
            name: name,
            edad: edad,
            categoria: categoria,
            descripcion: descripcion,
            image: image,
            rating: rating,
            experiencia: experiencia,
            emailTrabajador: emailTrabajador,
          ),
        ),
      );
    },
  );
}

class _ProfileContent extends StatefulWidget {
  final String name;
  final int edad;
  final String categoria;
  final String descripcion;
  final String image;
  final double rating;
  final int experiencia;
  final String emailTrabajador;

  const _ProfileContent({
    super.key,
    required this.name,
    required this.edad,
    required this.categoria,
    required this.descripcion,
    required this.image,
    required this.rating,
    required this.experiencia,
    required this.emailTrabajador,
  });

  @override
  State<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<_ProfileContent> {
  bool isFavorite = false;
  bool isLoadingFavorite = true;
  String? emailContratista;
  bool _isLoadingData = true;
  String? _errorData;
  int? _edadCalculada;
  double? _calificacionPromedio;
  String? _descripcionActual;
  String? _fotoTrabajadorBase64;
  List<Map<String, dynamic>> _reviews = [];
  String? _categoriaActual;
  int? _experienciaActual;
  String? _telefonoActual;
  Map<String, String>? _categoriasCache;

  @override
  void initState() {
    super.initState();
    _descripcionActual = widget.descripcion;
    _calificacionPromedio = widget.rating;
    _edadCalculada = widget.edad;
    _categoriaActual = widget.categoria;
    _experienciaActual = widget.experiencia;
    _cargarEstadoFavorito();
    _cargarDatosTrabajador();
  }

  Future<void> _cargarEstadoFavorito() async {
    try {
      final user = await StorageService.getUser();
      if (user != null) {
        emailContratista = user['email'];
        
        // Verificar si ya está en favoritos
        final resultado = await ApiService.verificarFavorito(
          emailContratista!,
          widget.emailTrabajador,
        );
        
        if (resultado['success'] == true) {
          setState(() {
            isFavorite = resultado['esFavorito'] ?? false;
            isLoadingFavorite = false;
          });
        } else {
          setState(() => isLoadingFavorite = false);
        }
      }
    } catch (e) {
      print('Error al verificar favorito: $e');
      setState(() => isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorito() async {
    if (emailContratista == null) {
      if (mounted) {
        CustomNotification.showError(
          context,
          'No se pudo obtener el usuario',
        );
      }
      return;
    }

    setState(() => isLoadingFavorite = true);

    try {
      Map<String, dynamic> resultado;
      
      if (isFavorite) {
        // Quitar de favoritos
        resultado = await ApiService.quitarFavorito(
          emailContratista!,
          widget.emailTrabajador,
        );
        
        if (resultado['success'] == true) {
          setState(() {
            isFavorite = false;
            isLoadingFavorite = false;
          });
          
          if (mounted) {
            CustomNotification.showInfo(
              context,
              'Quitado de favoritos',
            );
          }
        }
      } else {
        // Agregar a favoritos
        resultado = await ApiService.agregarFavorito(
          emailContratista!,
          widget.emailTrabajador,
        );
        
        if (resultado['success'] == true) {
          setState(() {
            isFavorite = true;
            isLoadingFavorite = false;
          });
          
          if (mounted) {
            CustomNotification.showSuccess(
              context,
              'Agregado a favoritos',
            );
          }
        }
      }
      
      // Manejar errores
      if (resultado['success'] != true) {
        setState(() => isLoadingFavorite = false);
        if (mounted) {
          CustomNotification.showError(
            context,
            resultado['error'] ?? "Error desconocido",
          );
        }
      }
    } catch (e) {
      setState(() => isLoadingFavorite = false);
      if (mounted) {
        CustomNotification.showError(
          context,
          'Error de red: $e',
        );
      }
    }
  }

  Future<void> _cargarDatosTrabajador() async {
    setState(() {
      _isLoadingData = true;
      _errorData = null;
    });

    try {
      final results = await Future.wait([
        ApiService.obtenerPerfilTrabajador(widget.emailTrabajador),
        ApiService.obtenerCalificacionesTrabajador(widget.emailTrabajador),
        ApiService.getCategorias(),
      ]);

      final perfilResponse = results[0] as Map<String, dynamic>;
      final reviewsResponse = results[1] as Map<String, dynamic>;
      final categoriasResponse = results[2] as Map<String, dynamic>;

      int? edadCalculada;
      String? descripcion;
      double? calificacionPromedio;
      String? fotoBase64;
      String? categoria;
      int? experiencia;
      String? telefono;
      String? errorMsg;

      if (categoriasResponse['success'] == true && categoriasResponse['data'] is List) {
        final cache = <String, String>{};
        for (final item in categoriasResponse['data'] as List<dynamic>) {
          if (item is Map<String, dynamic>) {
            final id = item['id_categoria']?.toString();
            final nombre = item['nombre']?.toString();
            if (id != null && nombre != null && nombre.trim().isNotEmpty) {
              cache[id] = _capitalizar(nombre);
            }
          }
        }
        if (cache.isNotEmpty) {
          _categoriasCache = cache;
        }
      }

      if (perfilResponse['success'] == true) {
        final data = perfilResponse['data'] as Map<String, dynamic>?
            ?? <String, dynamic>{};

        final fechaStr = data['fecha_nacimiento']?.toString();
        if (fechaStr != null && fechaStr.isNotEmpty) {
          final fecha = DateTime.tryParse(fechaStr);
          if (fecha != null) {
            edadCalculada = _calcularEdad(fecha);
          }
        }

        final desc = data['descripcion'];
        if (desc is String && desc.trim().isNotEmpty) {
          descripcion = desc.trim();
        }

        final calif = FormatService.parseDoubleNullable(data['calificacion_promedio']);
        if (calif != null) {
          calificacionPromedio = calif;
        }

        final foto = data['foto_perfil']?.toString();
        if (foto != null && foto.isNotEmpty) {
          fotoBase64 = foto;
        }

        final categoriaData = data['categoria'];
        if (categoriaData != null) {
          categoria = await _resolverCategoria(categoriaData.toString());
        }

        final experienciaData = data['experiencia'];
        experiencia = FormatService.parseInt(experienciaData);

        final telefonoData = data['telefono'];
        if (telefonoData != null) {
          telefono = telefonoData.toString();
        }
      } else {
        errorMsg = perfilResponse['error']?.toString() ??
            'No se pudo cargar la información del trabajador.';
      }

      List<Map<String, dynamic>> reviews = [];
      if (reviewsResponse['success'] == true) {
        final lista = reviewsResponse['data'] as List<dynamic>? ?? [];
        reviews = lista
            .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
            .toList();
      } else {
        errorMsg ??= reviewsResponse['error']?.toString() ??
            'No se pudieron cargar las reseñas.';
      }

      if (!mounted) return;
      setState(() {
        if (edadCalculada != null) {
          _edadCalculada = edadCalculada;
        }
        if (descripcion != null) {
          _descripcionActual = descripcion;
        }
        if (calificacionPromedio != null) {
          _calificacionPromedio = calificacionPromedio;
        }
        if (fotoBase64 != null) {
          _fotoTrabajadorBase64 = fotoBase64;
        }
        if (categoria != null && categoria.isNotEmpty) {
          _categoriaActual = categoria;
        }
        if (experiencia != null) {
          _experienciaActual = experiencia;
        }
        if (telefono != null && telefono.isNotEmpty) {
          _telefonoActual = telefono;
        }
        _reviews = reviews;
        _errorData = errorMsg;
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingData = false;
        _errorData = 'Error al cargar la información: $e';
      });
    }
  }

  int _calcularEdad(DateTime fecha) {
    final hoy = DateTime.now();
    int edad = hoy.year - fecha.year;
    if (hoy.month < fecha.month ||
        (hoy.month == fecha.month && hoy.day < fecha.day)) {
      edad--;
    }
    return edad;
  }

  ImageProvider _obtenerImagenTrabajador() {
    final bytes = _decodeImage(_fotoTrabajadorBase64);
    if (bytes != null) {
      return MemoryImage(bytes);
    }
    if (widget.image.startsWith('http')) {
      return NetworkImage(widget.image);
    }
    return AssetImage(widget.image);
  }

  Uint8List? _decodeImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      final cleaned = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  String _nombreContratista(Map<String, dynamic> review) {
    final nombre = (review['nombre_contratista'] ?? '').toString().trim();
    final apellido = (review['apellido_contratista'] ?? '').toString().trim();
    final completo = [nombre, apellido]
        .where((element) => element.isNotEmpty)
        .join(' ');
    if (completo.isNotEmpty) {
      return completo;
    }
    return review['email_contratista']?.toString() ?? 'Contratista';
  }

  String _capitalizar(String valor) {
    if (valor.isEmpty) return valor;
    return valor[0].toUpperCase() + valor.substring(1);
  }

  Future<String> _resolverCategoria(String raw) async {
    if (raw.isEmpty) return 'Sin categoría';

    final parsed = FormatService.parseInt(raw);
    if (parsed == 0 && raw != '0' && raw.isNotEmpty) {
      return _capitalizar(raw);
    }

    if (_categoriasCache != null && _categoriasCache!.isNotEmpty) {
      final nombre = _categoriasCache![parsed.toString()];
      if (nombre != null && nombre.isNotEmpty) {
        return nombre;
      }
    }

    return 'Categoría $parsed';
  }

  Widget _buildReviewsSection() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorData != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _errorData!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Aún no hay reseñas para este trabajador.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return Column(
      children: _reviews.map((review) {
        final nombre = _nombreContratista(review);
        final rating = FormatService.parseDouble(review['estrellas']);
        final comentario =
            (review['resena'] ?? 'Sin reseña.').toString().trim();
        final foto = review['foto_contratista']?.toString();
        final email = review['email_contratista']?.toString();

        return ReviewCard(
          nombre: nombre,
          comentario: comentario.isEmpty ? 'Sin reseña.' : comentario,
          rating: rating,
          fotoBase64: foto,
          email: email,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edadMostrar = _edadCalculada ?? widget.edad;
    final ratingMostrar = _calificacionPromedio ?? widget.rating;
    final descripcionMostrar = _descripcionActual ?? widget.descripcion;
    final categoriaMostrar =
        (_categoriaActual ?? widget.categoria).trim().isEmpty
            ? 'Sin categoría'
            : _categoriaActual ?? widget.categoria;
    final experienciaMostrar = _experienciaActual ?? widget.experiencia;
    return Column(
      children: [
        Container(
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 20),
        Stack(
          clipBehavior: Clip.none, // permite que el corazón sobresalga
          children: [
            CircleAvatar(radius: 80, backgroundImage: _obtenerImagenTrabajador()),
            Positioned(
              bottom: -10,
              right: -10,
              child: isLoadingFavorite
                ? Container(
                    padding: const EdgeInsets.all(12),
                    child: const CircularProgressIndicator(strokeWidth: 3),
                  )
                : IconButton(
                    icon: isFavorite
                        ? ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFE67E22),
                                  Color(0xFFF5B400),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds);
                            },
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 50,
                            ),
                          )
                        : const Icon(
                            Icons.favorite_border,
                            color: Colors.grey,
                            size: 50,
                          ),
                    onPressed: _toggleFavorito,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F4E79),
          ),
        ),
        Text(
          '$categoriaMostrar  •  $edadMostrar años',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, color: Colors.grey, size: 16),
            const SizedBox(width: 4),
            Text(
              widget.emailTrabajador,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            Text(
              ' ${ratingMostrar.toStringAsFixed(1)}  |  $experienciaMostrar años exp.',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(
          descripcionMostrar,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 25),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Reviews',
            style: TextStyle(
              color: Color(0xFFE67E22),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildReviewsSection(),
      ],
    );
  }
}
