import 'package:flutter/material.dart';
import'../login/login_view.dart';
import 'register_trabajador.dart';
import 'register_contratista.dart';
import '../../../core/utils/responsive.dart';

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
          ResponsiveContainer(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.getHorizontalPadding(context),
              vertical: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_obix.png',
                    height: Responsive.getResponsiveFontSize(
                      context,
                      mobile: 200,
                      tablet: 250,
                      desktop: 280,
                    ),
                  ),
                  SizedBox(
                    height: Responsive.getResponsiveSpacing(
                      context,
                      mobile: 20,
                      tablet: 30,
                      desktop: 40,
                    ),
                  ),
                  Card(
                    elevation: 8,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        Responsive.getResponsiveSpacing(
                          context,
                          mobile: 25,
                          tablet: 30,
                          desktop: 35,
                        ),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: Responsive.isMobile(context) 
                              ? double.infinity 
                              : 450,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Register",
                              style: TextStyle(
                                color: const Color(0xFFE67E22),
                                fontSize: Responsive.getResponsiveFontSize(
                                  context,
                                  mobile: 32,
                                  tablet: 36,
                                  desktop: 40,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 40,
                                tablet: 50,
                                desktop: 60,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 60,
                                        tablet: 80,
                                        desktop: 100,
                                      ),
                                      vertical: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 30,
                                        tablet: 35,
                                        desktop: 40,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Contratista",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 17,
                                        desktop: 18,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 30,
                                tablet: 35,
                                desktop: 40,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: DecoratedBox(
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 60,
                                        tablet: 80,
                                        desktop: 100,
                                      ),
                                      vertical: Responsive.getResponsiveSpacing(
                                        context,
                                        mobile: 30,
                                        tablet: 35,
                                        desktop: 40,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    "Trabajador",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: Responsive.getResponsiveFontSize(
                                        context,
                                        mobile: 16,
                                        tablet: 17,
                                        desktop: 18,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: Responsive.getResponsiveSpacing(
                                context,
                                mobile: 40,
                                tablet: 50,
                                desktop: 60,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginView(),
                                  ),
                                );
                              },
                              child: Text.rich(
                                TextSpan(
                                  text: "I have account? ",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: Responsive.getResponsiveFontSize(
                                      context,
                                      mobile: 14,
                                      tablet: 15,
                                      desktop: 16,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "Login",
                                      style: TextStyle(
                                        color: const Color(0xFFE67E22),
                                        fontSize: Responsive.getResponsiveFontSize(
                                          context,
                                          mobile: 14,
                                          tablet: 15,
                                          desktop: 16,
                                        ),
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
