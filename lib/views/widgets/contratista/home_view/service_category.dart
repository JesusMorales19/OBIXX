import 'package:flutter/material.dart';
import '../../../screens/contratista/see_more_employees.dart'; // Ajusta el import a tu ruta real

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
              style: const TextStyle(
                fontSize: 17,
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
              child: const Text(
                'Ver más',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
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
