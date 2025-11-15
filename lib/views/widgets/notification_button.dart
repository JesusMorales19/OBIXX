import 'dart:ui';
import 'package:flutter/material.dart';

class NotificationButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const NotificationButton({
    super.key,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
