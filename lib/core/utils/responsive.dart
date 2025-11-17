import 'package:flutter/material.dart';

/// Breakpoints para diseño responsivo
class Breakpoints {
  static const double mobile = 600;      // Móvil: < 600px
  static const double tablet = 1024;     // Tablet: 600px - 1024px
  // Desktop: > 1024px
}

/// Utilidades para diseño responsivo
class Responsive {
  /// Obtiene el ancho de la pantalla
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Obtiene la altura de la pantalla
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Verifica si es móvil (< 600px)
  static bool isMobile(BuildContext context) {
    return width(context) < Breakpoints.mobile;
  }

  /// Verifica si es tablet (600px - 1024px)
  static bool isTablet(BuildContext context) {
    final w = width(context);
    return w >= Breakpoints.mobile && w < Breakpoints.tablet;
  }

  /// Verifica si es desktop (> 1024px)
  static bool isDesktop(BuildContext context) {
    return width(context) >= Breakpoints.tablet;
  }

  /// Obtiene el número de columnas según el tamaño de pantalla
  /// Móvil: 1, Tablet: 2, Desktop: 3
  static int getColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  /// Obtiene el padding horizontal según el tamaño de pantalla
  static double getHorizontalPadding(BuildContext context) {
    if (isMobile(context)) return 15.0;
    if (isTablet(context)) return 30.0;
    return 50.0;
  }

  /// Obtiene el ancho máximo del contenido (útil para centrar en desktop)
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) return double.infinity;
    if (isTablet(context)) return 800.0;
    return 1200.0;
  }

  /// Obtiene el tamaño de fuente responsivo
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile * 1.2;
    return desktop ?? mobile * 1.4;
  }

  /// Obtiene el espaciado responsivo
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? mobile * 1.5;
    return desktop ?? mobile * 2.0;
  }
}

/// Widget que adapta su contenido según el tamaño de pantalla
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (Responsive.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Widget que limita el ancho del contenido y lo centra en pantallas grandes
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxW = maxWidth ?? Responsive.getMaxContentWidth(context);
    final pad = padding ?? EdgeInsets.symmetric(
      horizontal: Responsive.getHorizontalPadding(context),
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Padding(
          padding: pad,
          child: child,
        ),
      ),
    );
  }
}

