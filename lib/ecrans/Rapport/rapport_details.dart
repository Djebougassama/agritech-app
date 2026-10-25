import 'package:flutter/material.dart';
import 'package:agri_tech_app/modeles/rapport.dart';
import 'package:agri_tech_app/services/rapport_service.dart';

class RapportDetailsPage extends StatelessWidget {
  final Rapport rapport;

  const RapportDetailsPage({required this.rapport});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Détails du rapport")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Type : ${rapport.type}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text("Date : ${rapport.dateGeneration.toLocal().toString().split(' ')[0]}"),
            SizedBox(height: 20),
            Text("Contenu :", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text(rapport.contenu),
          ],
        ),
      ),
    );
  }
}
