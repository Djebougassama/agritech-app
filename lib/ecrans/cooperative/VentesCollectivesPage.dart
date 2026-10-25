import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class VentesCollectivesPage extends StatefulWidget {
  @override
  _VentesCollectivesPageState createState() => _VentesCollectivesPageState();
}

class _VentesCollectivesPageState extends State<VentesCollectivesPage> {
  String? cooperativeId;

  @override
  void initState() {
    super.initState();
    _fetchCooperativeId();
  }

  Future<void> _fetchCooperativeId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('cooperatives')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            cooperativeId = querySnapshot.docs.first.id;
          });
        } else {
          print("Aucune coopérative trouvée pour l'utilisateur ${user.uid}");
        }
      } catch (e) {
        print("Erreur lors de la récupération de la coopérative : $e");
      }
    }
  }

  Future<void> _updateVente(String venteId, double newPrix) async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;
    if (cooperativeId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('cooperatives')
            .doc(cooperativeId)
            .collection('ventesCollectives')
            .doc(venteId)
            .update({'prix': newPrix});
        print("Vente $venteId mise à jour avec succès");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'Vente mise à jour localement, synchronisation en attente'
                  : 'Vente mise à jour avec succès !',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
          ),
        );
      } catch (e) {
        print("Erreur lors de la mise à jour de la vente : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la mise à jour : $e')),
        );
      }
    }
  }

  Future<void> _deleteVente(String venteId) async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;
    if (cooperativeId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('cooperatives')
            .doc(cooperativeId)
            .collection('ventesCollectives')
            .doc(venteId)
            .delete();
        print("Vente $venteId supprimée avec succès");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'Vente supprimée localement, synchronisation en attente'
                  : 'Vente supprimée avec succès !',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
          ),
        );
      } catch (e) {
        print("Erreur lors de la suppression de la vente : $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  Future<void> _showUpdateDialog(String venteId, double currentPrix) async {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final _prixController = TextEditingController(text: currentPrix.toString());
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Modifier le prix',
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: screenWidth * 0.7,
            child: TextField(
              controller: _prixController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Nouveau prix',
                labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Annuler',
                style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
              ),
            ),
            TextButton(
              onPressed: () {
                final newPrix = double.tryParse(_prixController.text.trim()) ?? currentPrix;
                _updateVente(venteId, newPrix);
                Navigator.pop(context);
              },
              child: Text(
                'Sauvegarder',
                style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return cooperativeId == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  )
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('cooperatives')
                        .doc(cooperativeId)
                        .collection('ventesCollectives')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur de chargement : ${snapshot.error}',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 1.1 * textScaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucune vente disponible',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 1.1 * textScaleFactor,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      final ventes = snapshot.data!.docs;
                      if (isOffline) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Données chargées localement'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        });
                      }
                      return Column(
                        children: [
                          if (isOffline)
                            Padding(
                              padding: EdgeInsets.only(bottom: basePadding),
                              child: Text(
                                'Hors ligne - Données affichées localement',
                                style: GoogleFonts.lato(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: baseFontSize * 0.9 * textScaleFactor,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(screenWidth * 0.02),
                              child: ListView.builder(
                                itemCount: ventes.length,
                                itemBuilder: (context, index) {
                                  final vente = ventes[index];
                                  final data = vente.data() as Map<String, dynamic>? ?? {};
                                  final produit = data['produit'] ?? 'Inconnu';
                                  final quantiteTotale = data['quantiteTotale'] ?? 0;
                                  final unite = data['unite'] ?? 'kg';
                                  final prix = data['prix']?.toString() ?? 'N/A';
                                  final statut = data['statut'] ?? 'Inconnu';
                                  final venteId = vente.id;

                                  return Card(
                                    elevation: 3,
                                    margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    color: Colors.white,
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(screenWidth * 0.03),
                                      leading: Icon(
                                        Icons.local_shipping,
                                        color: Colors.green,
                                        size: baseFontSize * 1.5,
                                      ),
                                      title: Text(
                                        isOffline
                                            ? '$produit - $quantiteTotale $unite (local)'
                                            : '$produit - $quantiteTotale $unite',
                                        style: GoogleFonts.lato(
                                          fontSize: baseFontSize * 0.9 * textScaleFactor,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: screenWidth * 0.01),
                                          Text(
                                            isOffline ? 'Prix: $prix (local)' : 'Prix: $prix',
                                            style: GoogleFonts.lato(
                                              color: Colors.grey[600],
                                              fontSize: baseFontSize * 0.8 * textScaleFactor,
                                            ),
                                          ),
                                          Text(
                                            'Statut: $statut',
                                            style: GoogleFonts.lato(
                                              color: Colors.grey[600],
                                              fontSize: baseFontSize * 0.8 * textScaleFactor,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              color: Colors.blue,
                                              size: baseFontSize * 1.2,
                                            ),
                                            onPressed: () {
                                              final currentPrix = data['prix'] is num
                                                  ? (data['prix'] as num).toDouble()
                                                  : 0.0;
                                              _showUpdateDialog(venteId, currentPrix);
                                            },
                                            tooltip: 'Modifier',
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: baseFontSize * 1.2,
                                            ),
                                            onPressed: () {
                                              _deleteVente(venteId);
                                            },
                                            tooltip: 'Supprimer',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
          },
        ),
      ),
      appBar: AppBar(
        title: Text(
          'Ventes Collectives',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.1 * textScaleFactor,
          ),
        ),
        backgroundColor: Colors.green[700],
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
              size: baseFontSize * 1.5,
            ),
            onPressed: () {
              final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
              final bool isOffline = connectivityService.isOffline;
              if (isOffline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ajout enregistré localement, synchronisation en attente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              Navigator.pushNamed(context, '/venteGroupee');
            },
            tooltip: 'Ajouter une vente',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
          final bool isOffline = connectivityService.isOffline;
          if (isOffline) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ajout enregistré localement, synchronisation en attente'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          Navigator.pushNamed(context, '/venteGroupee');
        },
        backgroundColor: Colors.green[700],
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: baseFontSize * 1.5,
        ),
        elevation: 6,
        tooltip: 'Ajouter une vente',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}