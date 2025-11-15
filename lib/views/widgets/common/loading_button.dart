import 'package:flutter/material.dart';

/// Widget reutilizable para botones con estado de carga
class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final Size? minimumSize;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;
  final String? loadingText;
  final double? iconSize;
  final double? loadingIndicatorSize;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.minimumSize,
    this.borderRadius,
    this.textStyle,
    this.loadingText,
    this.iconSize = 18,
    this.loadingIndicatorSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: loadingIndicatorSize,
              height: loadingIndicatorSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  foregroundColor ?? Colors.white,
                ),
              ),
            )
          : icon != null
              ? Icon(icon, size: iconSize)
              : const SizedBox.shrink(),
      label: Text(isLoading ? (loadingText ?? 'Cargando...') : label),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: padding,
        minimumSize: minimumSize,
        shape: borderRadius != null
            ? RoundedRectangleBorder(borderRadius: borderRadius!)
            : null,
        textStyle: textStyle,
      ),
    );
  }
}

