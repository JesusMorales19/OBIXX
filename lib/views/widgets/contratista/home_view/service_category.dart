import 'package:flutter/material.dart';
import '../../../screens/contratista/see_more_employees.dart'; // Ajusta el import a tu ruta real
import '../../../../core/utils/responsive.dart';

class ServiceCategory extends StatelessWidget {
  final String title;
  final List<Widget> workers;

  const ServiceCategory({
    super.key,
    required this.title,
    required this.workers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 15,
                  tablet: 16,
                  desktop: 17,
                ),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeeMoreEmployees(category: title),
                  ),
                );
              },
              child: Text(
                'Ver más',
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
              ),
            ),
          ],
        ),
        ...workers,
      ],
    );
  }
}
