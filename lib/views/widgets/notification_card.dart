import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String nombre;
  final String descripcion;
  final List<Widget>? botones;

  const NotificationCard({
    super.key,
    required this.nombre,
    required this.descripcion,
    this.botones,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const Text(
                    "Notificación",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                descripcion,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.3),
              ),
              if (botones != null) ...[
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: botones!,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
