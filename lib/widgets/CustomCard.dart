import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  CustomCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
            ),
            SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}