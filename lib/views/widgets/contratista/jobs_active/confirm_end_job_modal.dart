import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';

class ConfirmEndJobModal extends StatelessWidget {
  final VoidCallback onConfirm;

  const ConfirmEndJobModal({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(
        Responsive.getResponsiveSpacing(
          context,
          mobile: 12,
          tablet: 14,
          desktop: 16,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: EdgeInsets.all(
          Responsive.getResponsiveSpacing(
            context,
            mobile: 15,
            tablet: 18,
            desktop: 20,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '¿Estás seguro?',
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 18,
                  tablet: 19,
                  desktop: 20,
                ),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F4E79),
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 10,
                tablet: 11,
                desktop: 12,
              ),
            ),
            Text(
              '¿Quieres terminar este trabajo?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
                color: Colors.black87,
              ),
            ),
            SizedBox(
              height: Responsive.getResponsiveSpacing(
                context,
                mobile: 15,
                tablet: 18,
                desktop: 20,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1F4E79)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: const Color(0xFF1F4E79),
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: Responsive.getResponsiveSpacing(
                    context,
                    mobile: 10,
                    tablet: 11,
                    desktop: 12,
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.getResponsiveSpacing(
                          context,
                          mobile: 12,
                          tablet: 13,
                          desktop: 14,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF1F4E79),
                    ),
                    child: Text(
                      'Aceptar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.getResponsiveFontSize(
                          context,
                          mobile: 14,
                          tablet: 15,
                          desktop: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
