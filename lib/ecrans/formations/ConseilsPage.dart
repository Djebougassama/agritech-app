import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';
import '../../modeles/conseil.dart';
import 'ajout_conseil.dart';
import 'DetailConseil.dart';

class ConseilsPage extends StatefulWidget {
  const ConseilsPage({Key? key}) : super(key: key);

  @override
  _ConseilsPageState createState() => _ConseilsPageState();
}

class _ConseilsPageState extends State<ConseilsPage> {
  String categorieSelectionnee = 'Toutes';
  String recherche = '';
  bool estAdmin = false;

  List<String> categories = [
    'Toutes',
    'Cultures',
    'Engrais',
    'Irrigation',
    'Machinerie',
    'Protection des Plantes',
    'Récolte',
    'Autres'
  ];

  @override
  void initState() {
    super.initState();
    verifierRole();
  }

  Future<void> verifierRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        setState(() {
          estAdmin = doc.data()?['role'] == 'admin';
        });
      } catch (e) {
        print("Erreur lors de la vérification du rôle : $e");
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Cultures':
        return Icons.eco;
      case 'Engrais':
        return Icons.grass;
      case 'Irrigation':
        return Icons.water_drop;
      case 'Machinerie':
        return Icons.agriculture;
      case 'Protection des Plantes':
        return Icons.health_and_safety;
      case 'Récolte':
        return Icons.shopping_basket;
      default:
        return Icons.lightbulb;
    }
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
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.02),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search, size: baseFontSize * 1.2),
                      border: OutlineInputBorder(),
                      labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                    ),
                    style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                    onChanged: (value) => setState(() => recherche = value.toLowerCase()),
                  ),
                ),
                SizedBox(
                  height: baseFontSize * 2.5,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          selected: categorieSelectionnee == cat,
                          selectedColor: Colors.green.shade300,
                          onSelected: (selected) => setState(() => categorieSelectionnee = cat),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: basePadding),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conseils')
                        .orderBy('datePublication', descending: true)
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
                            'Aucun conseil trouvé',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data!.docs;
                      final conseils = docs
                          .map((doc) => Conseil.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                          .toList();

                      final filtres = conseils.where((c) {
                        final matchCat = categorieSelectionnee == 'Toutes' || c.categorie == categorieSelectionnee;
                        final matchSearch = c.titre.toLowerCase().contains(recherche) ||
                            c.description.toLowerCase().contains(recherche);
                        return matchCat && matchSearch;
                      }).toList();

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
                        itemCount: filtres.length,
                        itemBuilder: (context, index) {
                          final conseil = filtres[index];
                          return Card(
                            margin: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenWidth * 0.015,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailConseilPage(
                                      conseil: conseil,
                                      isAdmin: estAdmin,
                                    ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: Icon(
                                  _getCategoryIcon(conseil.categorie),
                                  size: baseFontSize * 2.0,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  isOffline ? '${conseil.titre} (local)' : conseil.titre,
                                  style: GoogleFonts.lato(
                                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  isOffline ? '${conseil.description} (local)' : conseil.description,
                                  style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Text(
                                  isOffline ? '${conseil.categorie} (local)' : conseil.categorie,
                                  style: GoogleFonts.lato(
                                    fontSize: baseFontSize * 0.8 * textScaleFactor,
                                    color: Colors.green,
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
          "Conseils Agricoles",
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      floatingActionButton: estAdmin
          ? FloatingActionButton(
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
                  MaterialPageRoute(builder: (context) => const AjoutConseilPage()),
                );
              },
              backgroundColor: Colors.green.shade700,
              child: Icon(
                Icons.add,
                size: baseFontSize * 1.5,
              ),
            )
          : null,
    );
  }
}