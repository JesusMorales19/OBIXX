import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:integradora/views/widgets/contratista/home_view/assign_modal_work.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_modal.dart';
import '../../custom_notification.dart';

class WorkerCard extends StatelessWidget {
  final String name;
  final int edad;
  final String categoria;
  final String descripcion;
  final String status;
  final Color statusColor;
  final String image;
  final String? fotoPerfil;
  final double rating;
  final int experiencia;
  final String email;
  final String telefono;
  final bool disponible;
  final bool isAssignedToCurrent;
  final bool isAssignedToOther;
  final String? assignedJobType;
  final int? assignedJobId;
  final VoidCallback onAssignmentChanged;
  final Future<void> Function()? onCancelAssignment;

  const WorkerCard({
    super.key,
    required this.name,
    required this.edad,
    required this.categoria,
    required this.descripcion,
    required this.status,
    required this.statusColor,
    required this.image,
    this.fotoPerfil,
    required this.rating,
    required this.experiencia,
    required this.email,
    required this.telefono,
    required this.disponible,
    required this.isAssignedToCurrent,
    required this.isAssignedToOther,
    required this.assignedJobType,
    required this.assignedJobId,
    required this.onAssignmentChanged,
    this.onCancelAssignment,
  });

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

  Widget _buildAvatar() {
    final bytes = _decodeImage(fotoPerfil);
    final hasImage = bytes != null;

    return CircleAvatar(
      radius: 30,
      backgroundColor: hasImage
          ? Colors.transparent
          : const Color(0xFFFFF3E0),
      backgroundImage: hasImage
          ? MemoryImage(bytes!)
          : null,
      child: !hasImage
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 24,
                color: Color(0xFF1F4E79),
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Future<void> _contactarTrabajador(BuildContext context) async {
    final sanitizedPhone = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    if (sanitizedPhone.isEmpty) {
      CustomNotification.showError(
        context,
        'El trabajador no tiene un número de teléfono válido',
      );
      return;
    }

    // Intentar abrir WhatsApp primero
    final uri = Uri.parse('https://wa.me/$sanitizedPhone');
    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      launched = false;
    }

    if (!launched && context.mounted) {
      CustomNotification.showError(
        context,
        'No se pudo abrir WhatsApp',
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    final bool puedeContratar = disponible && !isAssignedToCurrent && !isAssignedToOther;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              _buildAvatar(),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF1F4E79),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$experiencia años experiencia',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ...List.generate(
                      fullStars,
                      (index) => const Icon(Icons.star, color: Colors.amber, size: 13),
                    ),
                    if (hasHalfStar)
                      const Icon(Icons.star_half, color: Colors.amber, size: 13),
                    Text(
                      '  ${rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildPrimaryButton(context),
              const SizedBox(height: 4),
              _buildSecondaryButton(context, puedeContratar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    if (isAssignedToCurrent) {
      return SizedBox(
        width: 90,
        height: 30,
        child: TextButton(
          onPressed: onCancelAssignment == null
              ? null
              : () async {
                  await onCancelAssignment!();
                },
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            minimumSize: const Size(90, 30),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.red,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 90,
      height: 30,
      child: TextButton(
        onPressed: () {
          showProfileModal(
            context,
            name,
            edad,
            categoria,
            descripcion,
            image,
            rating,
            experiencia,
            status,
            statusColor,
            email,
            telefono,
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade100,
          minimumSize: const Size(90, 30),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Ver perfil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, bool puedeContratar) {
    if (isAssignedToCurrent) {
      return SizedBox(
        width: 90,
        height: 30,
        child: ElevatedButton(
          onPressed: () => _contactarTrabajador(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Contactar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (!puedeContratar) {
      return SizedBox(
        width: 90,
        height: 30,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade400,
            disabledBackgroundColor: Colors.grey.shade400,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.zero,
          ),
          child: const Text(
            'Contratar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 90,
      height: 30,
      child: ElevatedButton(
        onPressed: () {
          showAsignarTrabajoModal(
            context: context,
            nombreTrabajador: name,
            categoriaTrabajador: categoria,
            emailTrabajador: email,
            onAssignmentCompleted: onAssignmentChanged,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF5B400),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: const Text(
          'Contratar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
