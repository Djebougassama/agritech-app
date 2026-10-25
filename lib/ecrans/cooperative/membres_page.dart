import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';
import 'ajout_membre.dart';
import 'DetailMembrePage.dart';

class ListeMembresPage extends StatefulWidget {
  const ListeMembresPage({Key? key}) : super(key: key);

  @override
  _ListeMembresPageState createState() => _ListeMembresPageState();
}

class _ListeMembresPageState extends State<ListeMembresPage> {
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
      });
    } else {
      print("Aucun utilisateur connecté");
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4CAF50);
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return currentUserId == null
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4CAF50),
                    ),
                  )
                : Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenWidth * 0.02,
                    ),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('membres')
                          .where('userId', isEqualTo: currentUserId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Erreur de chargement : ${snapshot.error}",
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
                              "Aucun membre trouvé",
                              style: GoogleFonts.lato(
                                fontSize: baseFontSize * 0.9 * textScaleFactor,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        }

                        final membres = snapshot.data!.docs;
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
                                  "Hors ligne - Données affichées localement",
                                  style: GoogleFonts.lato(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: membres.length,
                                separatorBuilder: (context, index) => SizedBox(height: screenWidth * 0.02),
                                itemBuilder: (context, index) {
                                  final membre = membres[index].data() as Map<String, dynamic>;
                                  final docId = membres[index].id;

                                  return Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: screenWidth * 0.04,
                                        vertical: screenWidth * 0.03,
                                      ),
                                      leading: CircleAvatar(
                                        radius: baseFontSize * 1.5,
                                        backgroundImage: membre['photo'] != null
                                            ? NetworkImage(membre['photo'])
                                            : null,
                                        child: membre['photo'] == null
                                            ? Icon(Icons.person, size: baseFontSize * 1.5, color: Colors.white)
                                            : null,
                                        backgroundColor: primaryColor,
                                      ),
                                      title: Text(
                                        isOffline
                                            ? "${membre['nom'] ?? 'Sans nom'} (local)"
                                            : membre['nom'] ?? 'Sans nom',
                                        style: GoogleFonts.lato(
                                          fontWeight: FontWeight.bold,
                                          fontSize: baseFontSize * 0.9 * textScaleFactor,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      subtitle: Text(
                                        isOffline
                                            ? "${membre['culture'] ?? ''} (local)"
                                            : membre['culture'] ?? '',
                                        style: GoogleFonts.lato(
                                          fontSize: baseFontSize * 0.8 * textScaleFactor,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      trailing: Icon(
                                        Icons.arrow_forward_ios,
                                        size: baseFontSize * 0.9,
                                        color: Colors.grey,
                                      ),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                DetailMembrePage(membre: membre, docId: docId),
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
                  );
          },
        ),
      ),
      appBar: AppBar(
        title: Text(
          "Liste des membres",
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: baseFontSize * 1.1 * textScaleFactor,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
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
            MaterialPageRoute(builder: (context) => const AjoutMembrePage()),
          );
        },
        label: Text(
          "Ajouter",
          style: GoogleFonts.lato(
            color: Colors.white,
            fontSize: baseFontSize * 0.8 * textScaleFactor,
          ),
        ),
        icon: Icon(
          Icons.add,
          color: Colors.white,
          size: baseFontSize * 1.2,
        ),
        backgroundColor: primaryColor,
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}