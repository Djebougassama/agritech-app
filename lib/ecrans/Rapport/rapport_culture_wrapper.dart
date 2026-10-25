import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../modeles/culture.dart';
import '../../services/connectivity_service.dart';
import 'rapport_culture.dart';

class RapportCulturePageWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.green[50],
        appBar: AppBar(
          title: Text(
            "Non connecté",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 1.1 * textScaleFactor,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green[700],
        ),
        body: SafeArea(
          child: Center(
            child: Text(
              "Veuillez vous connecter pour voir vos rapports.",
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.9 * textScaleFactor,
                color: Colors.green[700],
              ),
            ),
          ),
        ),
      );
    }

    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, child) {
        final bool isOffline = connectivityService.isOffline;
        return Scaffold(
          backgroundColor: Colors.green[50],
          appBar: AppBar(
            title: Text(
              "Chargement des rapports",
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 1.1 * textScaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green[700],
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: baseFontSize * 1.2),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Retour',
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (isOffline)
                  Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Text(
                      'Hors ligne - Données locales',
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('cultures')
                        .where('userId', isEqualTo: user.uid)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Une erreur est survenue: ${snapshot.error}",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }

                      final cultures = snapshot.data!.docs.map((doc) {
                        return Culture.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                      }).toList();

                      return RapportCulturePage(cultures: cultures);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}