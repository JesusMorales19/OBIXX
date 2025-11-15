import 'package:flutter/material.dart';

class BackgroundHeader extends StatelessWidget {
  const BackgroundHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1F4E79),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, 20),
          ),
        ],
      ),
    );
  }
}
