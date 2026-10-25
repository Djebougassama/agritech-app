import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/connectivity_service.dart';
import 'package:agri_tech_app/ecrans/ventes/ecran_ajout_vente.dart';
import 'package:agri_tech_app/ecrans/ventes/VenteDetailPage.dart';
import 'package:agri_tech_app/ecrans/Rapport/rapport_vente.dart';

class ListeVentes extends StatelessWidget {
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
            return Column(
              children: [
                if (isOffline)
                  Padding(
                    padding: EdgeInsets.all(basePadding),
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
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('ventes').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur de chargement : ${snapshot.error}',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
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
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                        );
                      }

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

                      return Padding(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: screenWidth < 600 ? 2 : 3,
                            crossAxisSpacing: basePadding,
                            mainAxisSpacing: basePadding,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            var venteDoc = snapshot.data!.docs[index];
                            var venteData = venteDoc.data() as Map<String, dynamic>;
                            venteData['id'] = venteDoc.id;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VenteDetailPage(vente: venteData),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                        child: Image.network(
                                          venteData['imageUrl'] ?? 'https://via.placeholder.com/150',
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Image.network(
                                            'https://via.placeholder.com/150',
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(screenWidth * 0.02),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isOffline ? "${venteData['produit']} (local)" : venteData['produit'],
                                            style: GoogleFonts.lato(
                                              fontWeight: FontWeight.bold,
                                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: basePadding * 0.5),
                                          Text(
                                            isOffline
                                                ? "Prix : ${venteData['prixUnitaire']} GNF (local)"
                                                : "Prix : ${venteData['prixUnitaire']} GNF",
                                            style: GoogleFonts.lato(
                                              fontSize: baseFontSize * 0.8 * textScaleFactor,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                          Text(
                                            isOffline
                                                ? "Qté : ${venteData['quantite']} (local)"
                                                : "Qté : ${venteData['quantite']}",
                                            style: GoogleFonts.lato(
                                              fontSize: baseFontSize * 0.8 * textScaleFactor,
                                              color: Colors.green[800],
                                            ),
                                          ),
                                          SizedBox(height: basePadding * 0.5),
                                          Text(
                                            isOffline
                                                ? "${venteData['description'] ?? 'Aucune description'} (local)"
                                                : venteData['description'] ?? "Aucune description",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.lato(
                                              fontSize: baseFontSize * 0.7 * textScaleFactor,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              color: Colors.white,
              size: baseFontSize * 1.5,
            ),
            SizedBox(width: basePadding),
            Text(
              "Boutique Agricole",
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.1 * textScaleFactor,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.insert_chart,
              color: Colors.white,
              size: baseFontSize * 1.5,
            ),
            tooltip: 'Voir Rapport',
            onPressed: () {
              final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
              final bool isOffline = connectivityService.isOffline;
              if (isOffline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Rapport chargé localement'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RapportVentePage()),
              );
            },
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AjoutVente()),
          );
        },
        child: Icon(
          Icons.add,
          size: baseFontSize * 1.5,
        ),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}