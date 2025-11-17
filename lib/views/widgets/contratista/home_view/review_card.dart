import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

class ReviewCard extends StatelessWidget {
  final String nombre;
  final String comentario;
  final double rating;
  final String? fotoBase64;
  final String? email;

  const ReviewCard({
    super.key,
    required this.nombre,
    required this.comentario,
    required this.rating,
    this.fotoBase64,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = _decodeImage(fotoBase64);
    final initials = _buildInitials();

    return Container(
      margin: EdgeInsets.only(
        bottom: Responsive.getResponsiveSpacing(
          context,
          mobile: 10,
          tablet: 11,
          desktop: 12,
        ),
      ),
      padding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 10,
          tablet: 11,
          desktop: 12,
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: Responsive.getResponsiveFontSize(
              context,
              mobile: 20,
              tablet: 22,
              desktop: 24,
            ),
            backgroundImage: bytes != null ? MemoryImage(bytes) : null,
            backgroundColor: Colors.orangeAccent,
            child: bytes == null
                ? Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getResponsiveFontSize(
                        context,
                        mobile: 12,
                        tablet: 13,
                        desktop: 14,
                      ),
                    ),
                  )
                : null,
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
                  nombre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 12,
                      tablet: 13,
                      desktop: 13.5,
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
                Row(
                  children: [
                    ..._buildStars(context),
                    SizedBox(
                      width: Responsive.getResponsiveSpacing(
                        context,
                        mobile: 3,
                        tablet: 3.5,
                        desktop: 4,
                      ),
                    ),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 11,
                          tablet: 11.5,
                          desktop: 12,
                        ),
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 5,
                    tablet: 5.5,
                    desktop: 6,
                  ),
                ),
                Text(
                  comentario,
                  style: TextStyle(
                    fontSize: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 11,
                      tablet: 11.5,
                      desktop: 12,
                    ),
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Uint8List? _decodeImage(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      final cleaned = value.contains(',') ? value.split(',').last : value;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  String _buildInitials() {
    final base = nombre.trim().isNotEmpty
        ? nombre
        : (email?.trim().isNotEmpty ?? false ? email! : 'CT');
    final parts = base.split(' ');
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts[0].substring(0, 1).toUpperCase();
    final second = parts[1].substring(0, 1).toUpperCase();
    return '$first$second';
  }

  List<Widget> _buildStars(BuildContext context) {
    final stars = <Widget>[];
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;
    final starSize = Responsive.getResponsiveFontSize(
      context,
      mobile: 12,
      tablet: 13,
      desktop: 14,
    );

    for (var i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(Icon(Icons.star, size: starSize, color: Colors.amber));
      } else if (i == fullStars && hasHalf) {
        stars.add(Icon(Icons.star_half, size: starSize, color: Colors.amber));
      } else {
        stars.add(Icon(Icons.star_border,
            size: starSize, color: Colors.amber.withOpacity(0.7)));
      }
    }

    return stars;
  }
}
