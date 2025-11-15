import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: bytes != null ? MemoryImage(bytes) : null,
            backgroundColor: Colors.orangeAccent,
            child: bytes == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ..._buildStars(),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comentario,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
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

  List<Widget> _buildStars() {
    final stars = <Widget>[];
    final fullStars = rating.floor();
    final hasHalf = (rating - fullStars) >= 0.5;

    for (var i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, size: 14, color: Colors.amber));
      } else if (i == fullStars && hasHalf) {
        stars.add(const Icon(Icons.star_half, size: 14, color: Colors.amber));
      } else {
        stars.add(Icon(Icons.star_border,
            size: 14, color: Colors.amber.withOpacity(0.7)));
      }
    }

    return stars;
  }
}
