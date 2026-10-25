import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class DetailRecoltePage extends StatefulWidget {
  @override
  _DetailRecoltePageState createState() => _DetailRecoltePageState();
}

class _DetailRecoltePageState extends State<DetailRecoltePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String recolteId;
  Map<String, dynamic>? recolteDetails;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is String && arguments.isNotEmpty) {
      recolteId = arguments;
      _getRecolteDetails();
    } else {
      print("L'ID de la récolte est invalide ou manquant.");
    }
  }

  void _getRecolteDetails() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    try {
      DocumentSnapshot doc = await _firestore.collection('recoltesCoop').doc(recolteId).get();
      setState(() {
        recolteDetails = doc.data() as Map<String, dynamic>?;
      });
      if (isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Détails chargés localement'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de récupération de la récolte : $e')),
      );
    }
  }

  void _deleteRecolte() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    try {
      await _firestore.collection('recoltesCoop').doc(recolteId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'Récolte supprimée localement, synchronisation en attente'
                : 'Récolte supprimée avec succès !',
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de suppression de la récolte : $e')),
      );
    }
  }

  void _navigateToEditPage() {
    if (recolteDetails != null) {
      Navigator.pushNamed(
        context,
        '/editRecolte',
        arguments: {
          'id': recolteId,
          'produit': recolteDetails!['produit'].toString(),
          'quantite': recolteDetails!['quantite'].toString(),
          'dateRecolte': recolteDetails!['dateRecolte'],
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (recolteDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Détail de la récolte"),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détail de la récolte"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirmation"),
                  content: const Text("Êtes-vous sûr de vouloir supprimer cette récolte ?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Annuler"),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteRecolte();
                        Navigator.pop(context);
                      },
                      child: const Text("Supprimer"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
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
                      "Hors ligne - Données affichées localement",
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                _buildDetailCard("Produit", recolteDetails?['produit'], isOffline: isOffline),
                _buildDetailCard("Quantité", recolteDetails?['quantite'].toString(), isOffline: isOffline),
                _buildDetailCard(
                  "Récolté le",
                  recolteDetails?['dateRecolte'] != null
                      ? (recolteDetails!['dateRecolte'] as Timestamp).toDate().toString()
                      : 'Date non renseignée',
                  isOffline: isOffline,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard(String title, String? value, {required bool isOffline}) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
        ),
        subtitle: Text(isOffline ? "${value ?? 'Non renseigné'} (local)" : value ?? 'Non renseigné'),
      ),
    );
  }
}