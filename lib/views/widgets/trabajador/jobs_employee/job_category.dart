import 'package:flutter/material.dart';
import '../../../screens/trabajador/see_more_jobs.dart';
import '../../../../core/utils/responsive.dart';

class JobCategory extends StatelessWidget {
  final String title;
  final List<Widget> jobs;
  final String tipoUsuario; // nuevo parámetro

  const JobCategory({
    super.key,
    required this.title,
    required this.jobs,
    required this.tipoUsuario,
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
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.getResponsiveFontSize(
                  context,
                  mobile: 14,
                  tablet: 15,
                  desktop: 16,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // 👇 Navega dependiendo del título
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VerMasScreen(
                      tipoUsuario: tipoUsuario,
                      categoria: title,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(
                  Responsive.getResponsiveSpacing(
                    context,
                    mobile: 35,
                    tablet: 37,
                    desktop: 40,
                  ),
                  Responsive.getResponsiveSpacing(
                    context,
                    mobile: 22,
                    tablet: 23,
                    desktop: 25,
                  ),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Ver más',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Responsive.getResponsiveFontSize(
                    context,
                    mobile: 11,
                    tablet: 12,
                    desktop: 13,
                  ),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: Responsive.getResponsiveSpacing(
            context,
            mobile: 8,
            tablet: 9,
            desktop: 10,
          ),
        ),
        ...jobs,
      ],
    );
  }
}
