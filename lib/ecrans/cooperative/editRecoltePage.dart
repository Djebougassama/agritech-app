import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class EditRecoltePage extends StatefulWidget {
  @override
  _EditRecoltePageState createState() => _EditRecoltePageState();
}

class _EditRecoltePageState extends State<EditRecoltePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String recolteId;
  late TextEditingController _produitController;
  late TextEditingController _quantiteController;
  late TextEditingController _dateRecolteController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is Map<String, dynamic>) {
      recolteId = arguments['id'];
      _produitController = TextEditingController(text: arguments['produit']);
      _quantiteController = TextEditingController(text: arguments['quantite']);
      _dateRecolteController = TextEditingController(
        text: arguments['dateRecolte']?.toDate().toString() ?? '',
      );
    }
  }

  void _saveRecolte() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    try {
      await _firestore.collection('recoltesCoop').doc(recolteId).update({
        'produit': _produitController.text,
        'quantite': _quantiteController.text,
        'dateRecolte': DateTime.parse(_dateRecolteController.text),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'Modifications enregistrées localement, synchronisation en attente'
                : 'Récolte mise à jour avec succès !',
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de mise à jour de la récolte : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier la récolte"),
        backgroundColor: Colors.green,
      ),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          final bool isOffline = connectivityService.isOffline;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                if (isOffline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Hors ligne - Modifications enregistrées localement",
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                TextField(
                  controller: _produitController,
                  decoration: InputDecoration(
                    labelText: isOffline ? "Produit (local)" : "Produit",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _quantiteController,
                  decoration: InputDecoration(
                    labelText: isOffline ? "Quantité (local)" : "Quantité",
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _dateRecolteController,
                  decoration: InputDecoration(
                    labelText: isOffline ? "Date de récolte (YYYY-MM-DD) (local)" : "Date de récolte (YYYY-MM-DD)",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _saveRecolte,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Sauvegarder"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}