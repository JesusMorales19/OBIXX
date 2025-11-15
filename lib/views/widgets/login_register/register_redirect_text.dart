import 'package:flutter/material.dart';

class RegisterRedirectText extends StatelessWidget {
  final String text;
  final String actionText;
  final VoidCallback onTap;

  const RegisterRedirectText({
    super.key,
    required this.text,
    required this.actionText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: actionText,
              style: const TextStyle(
                color: Color(0xFFE67E22),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
