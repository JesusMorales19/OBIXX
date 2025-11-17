import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:integradora/views/widgets/contratista/home_view/assign_modal_work.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_modal.dart';
import '../../custom_notification.dart';
import '../../../../core/utils/responsive.dart';

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

  Widget _buildAvatar(BuildContext context) {
    final bytes = _decodeImage(fotoPerfil);
    final hasImage = bytes != null;

    return CircleAvatar(
      radius: Responsive.getResponsiveFontSize(
        context,
        mobile: 25,
        tablet: 27,
        desktop: 30,
      ),
      backgroundColor: hasImage
          ? Colors.transparent
          : const Color(0xFFFFF3E0),
      backgroundImage: hasImage
          ? MemoryImage(bytes!)
          : null,
      child: !hasImage
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 20,
                  tablet: 22,
                  desktop: 24,
                ),
                color: const Color(0xFF1F4E79),
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
      margin: EdgeInsets.only(
        bottom: Responsive.getResponsiveSpacing(
          context,
          mobile: 15,
          tablet: 18,
          desktop: 20,
        ),
      ),
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 13,
          desktop: 15,
        ),
      ),
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
              _buildAvatar(context),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 3,
                  tablet: 3.5,
                  desktop: 4,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 4,
                    tablet: 4.5,
                    desktop: 5,
                  ),
                  vertical: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 0.5,
                    tablet: 0.75,
                    desktop: 1,
                  ),
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 8,
                      tablet: 8.5,
                      desktop: 9,
                    ),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: Responsive.getResponsiveSpacing(
              context,
              mobile: 8,
              tablet: 9,
              desktop: 10,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: const Color(0xFF1F4E79),
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 12.5,
                      desktop: 13,
                    ),
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 3,
                    tablet: 3.5,
                    desktop: 4,
                  ),
                ),
                Text(
                  '$experiencia años experiencia',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 10,
                      tablet: 10.5,
                      desktop: 11,
                    ),
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 5,
                    tablet: 5.5,
                    desktop: 6,
                  ),
                ),
                Row(
                  children: [
                    ...List.generate(
                      fullStars,
                      (index) => Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 12.5,
                          desktop: 13,
                        ),
                      ),
                    ),
                    if (hasHalfStar)
                      Icon(
                        Icons.star_half,
                        color: Colors.amber,
                        size: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 12,
                          tablet: 12.5,
                          desktop: 13,
                        ),
                      ),
                    Text(
                      '  ${rating.toStringAsFixed(1)} / 5.0',
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 10,
                          tablet: 10.5,
                          desktop: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildPrimaryButton(context),
              SizedBox(
                height: Responsive.getResponsiveSpacing(
                  context,
                  mobile: 3,
                  tablet: 3.5,
                  desktop: 4,
                ),
              ),
              _buildSecondaryButton(context, puedeContratar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton(BuildContext context) {
    final buttonWidth = (Responsive.isMobile(context) ? 85.0 : 90.0);
    final buttonHeight = Responsive.getResponsiveSpacing(
      context,
      mobile: 28,
      tablet: 29,
      desktop: 30,
    );
    final fontSize = Responsive.getResponsiveFontSize(
      context,
      mobile: 10,
      tablet: 10.5,
      desktop: 11,
    );

    if (isAssignedToCurrent) {
      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: TextButton(
          onPressed: onCancelAssignment == null
              ? null
              : () async {
                  await onCancelAssignment!();
                },
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            minimumSize: Size(buttonWidth, buttonHeight),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.red,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
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
          minimumSize: Size(buttonWidth, buttonHeight),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          'Ver perfil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, bool puedeContratar) {
    final buttonWidth = (Responsive.isMobile(context) ? 85.0 : 90.0);
    final buttonHeight = Responsive.getResponsiveSpacing(
      context,
      mobile: 28,
      tablet: 29,
      desktop: 30,
    );
    final fontSize = Responsive.getResponsiveFontSize(
      context,
      mobile: 10,
      tablet: 10.5,
      desktop: 11,
    );

    if (isAssignedToCurrent) {
      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
        child: ElevatedButton(
          onPressed: () => _contactarTrabajador(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            'Contactar',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (!puedeContratar) {
      return SizedBox(
        width: buttonWidth,
        height: buttonHeight,
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
          child: Text(
            'Contratar',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: buttonWidth,
      height: buttonHeight,
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
        child: Text(
          'Contratar',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
