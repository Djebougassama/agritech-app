import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/connectivity_service.dart';
import 'video_player_screen.dart';
import 'AjoutFormationPage.dart';

class FormationsPage extends StatelessWidget {
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
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('formations')
                        .orderBy('titre')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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
                            'Aucune formation disponible',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.grey,
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

                      return ListView.builder(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final formation = snapshot.data!.docs[index];
                          final data = formation.data() as Map<String, dynamic>;

                          return Card(
                            margin: EdgeInsets.all(screenWidth * 0.02),
                            child: ListTile(
                              leading: Icon(
                                Icons.play_circle_outline,
                                color: Colors.green,
                                size: baseFontSize * 1.8,
                              ),
                              title: Text(
                                isOffline ? "${data['titre']} (local)" : data['titre'],
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.9 * textScaleFactor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                isOffline
                                    ? "${data['duree']} min - ${data['niveau']} (local)"
                                    : "${data['duree']} min - ${data['niveau']}",
                                style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                size: baseFontSize * 1.2,
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                    videoUrl: data['url'],
                                    titre: data['titre'],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
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
        title: Text(
          'Formations Agricoles',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AjoutFormationPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}