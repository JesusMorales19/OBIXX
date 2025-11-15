import 'package:flutter/material.dart';
import '../../../screens/trabajador/see_more_jobs.dart';

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
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                minimumSize: const Size(40, 25),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Ver más',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...jobs,
      ],
    );
  }
}
