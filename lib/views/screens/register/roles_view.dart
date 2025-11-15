import 'package:flutter/material.dart';
import'../login/login_view.dart';
import 'register_trabajador.dart';
import 'register_contratista.dart';

class RolesView extends StatefulWidget {
  const RolesView({super.key});
  

  @override
  State<RolesView> createState() => _RolesViewState();
}

class _RolesViewState extends State<RolesView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Fondo blanco de toda la pantalla
          Container(color: const Color(0xFFF9FAFB)),

          // 🔹 Parte azul con border radius en las esquinas inferiores
Container(
  height: MediaQuery.of(context).size.height * 0.5, // Mitad superior
  width: double.infinity,
  decoration: const BoxDecoration(
    color: Color(0xFF1F4E79),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(40),
      bottomRight: Radius.circular(40),
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,  // sombra suave y semi-transparente
        blurRadius: 20,         // qué tan borroso es el borde
        spreadRadius: 0,       // controla la extensión de la sombra
        offset: Offset(0, 20),  // mueve la sombra hacia abajo
      ),
    ],
  ),
),


          // 🔹 Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_obix.png',
                    height: 280,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400, // Mantiene tu ancho original
                    child: Card(
                      elevation: 8,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            const Text(
                              "Register",
                              style: TextStyle(
                                color: Color(0xFFE67E22),
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 60),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE67E22),
                                    Color(0xFFF5B400),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ElevatedButton(
                                onPressed: () {Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterContratista(),
                                  ),
                                );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 100,
                                    vertical: 40,
                                  ),
                                ),
                                child: const Text(
                                  "Contratista",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE67E22),
                                    Color(0xFFF5B400),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ElevatedButton(
                                onPressed: () {Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterTrabajador(),
                                  ),
                                );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 100,
                                    vertical: 40,
                                  ),
                                ),
                                child: const Text(
                                  "Trabajador",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginView(),
                                  ),
                                );
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text: "I have account? ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Login",
                                      style: TextStyle(
                                        color: Color(0xFFE67E22),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
