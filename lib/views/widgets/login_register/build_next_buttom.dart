import 'package:flutter/material.dart';

class NextButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool enabled;

  const NextButton({
    super.key,
    required this.text,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [Color(0xFFE67E22), Color(0xFFF5B400)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : const LinearGradient(
                colors: [Colors.grey, Colors.grey],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          padding: const EdgeInsets.symmetric(vertical: 20),
          disabledBackgroundColor: Colors.transparent,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.grey[300],
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
