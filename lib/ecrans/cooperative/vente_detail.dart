import 'package:flutter/material.dart';

class VenteDetailPage extends StatefulWidget {
  final String venteId;

  VenteDetailPage({required this.venteId});

  @override
  _VenteDetailPageState createState() => _VenteDetailPageState();
}

class _VenteDetailPageState extends State<VenteDetailPage> {
  @override
  void initState() {
    super.initState();
    print("VenteDetailPage initialisée avec venteId: ${widget.venteId}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la vente'),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Détail de la vente ID: ${widget.venteId}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}