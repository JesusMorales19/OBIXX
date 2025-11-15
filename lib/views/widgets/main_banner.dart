import 'package:flutter/material.dart';

class MainBanner extends StatelessWidget {
  const MainBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/construccion.png',
            width: MediaQuery.of(context).size.width,
            height: 250,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 90,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
