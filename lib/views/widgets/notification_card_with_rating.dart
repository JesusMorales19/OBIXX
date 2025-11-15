import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationCardWithRating extends StatefulWidget {
  final String nombre;
  final String descripcion;

  const NotificationCardWithRating({
    super.key,
    required this.nombre,
    required this.descripcion,
  });

  @override
  State<NotificationCardWithRating> createState() =>
      _NotificationCardWithRatingState();
}

class _NotificationCardWithRatingState
    extends State<NotificationCardWithRating> {
  double rating = 0;
  final TextEditingController _controller = TextEditingController();

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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.nombre,
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
                widget.descripcion,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  '${rating.toInt()}/5.0',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => GestureDetector(
                    onTap: () => setState(() => rating = index + 1),
                    child: Icon(
                      Icons.star,
                      color: index < rating ? Colors.amber : Colors.white70,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: TextField(
                    controller: _controller,
                    maxLength: 100,
                    decoration: InputDecoration(
                      counterStyle: const TextStyle(color: Colors.white70),
                      hintText: "Escribir reseña",
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.22),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Ayuda al trabajador a obtener más reputación a través de tu reseña.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'Calificar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
