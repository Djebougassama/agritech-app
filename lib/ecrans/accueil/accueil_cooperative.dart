import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:badges/badges.dart' as badges;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_tech_app/ecrans/formations/ConseilsPage.dart';
import 'package:agri_tech_app/ecrans/formations/FormationsPage.dart';
import 'package:agri_tech_app/ecrans/cooperative/membres_page.dart';
import 'package:agri_tech_app/ecrans/cooperative/liste_recoltes_page.dart';
import 'package:agri_tech_app/ecrans/cooperative/VentesCollectivesPage.dart';
import 'package:agri_tech_app/ecrans/cooperative/liste_stocks_page.dart';
import 'package:agri_tech_app/ecrans/ventes/TransactionsPage.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Aide_page.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Parametres_page.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Utilisateur_profil.dart';
import 'package:agri_tech_app/ecrans/Notifications/notifications_page.dart';
import 'package:provider/provider.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class AccueilCooperative extends StatefulWidget {
  final String cooperativeId;

  const AccueilCooperative({super.key, required this.cooperativeId});

  @override
  _AccueilCooperativeState createState() => _AccueilCooperativeState();
}

class _AccueilCooperativeState extends State<AccueilCooperative> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    // Implementation remains the same
  }

  Future<void> _logout() async {
    // Implementation remains the same
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.agriculture, color: Colors.white, size: isSmallScreen ? 24 : 30),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              "AgriTech Coop",
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 18 : 22,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: badges.Badge(
              badgeContent: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10)),
              child: Icon(Icons.notifications_none, size: isSmallScreen ? 20 : 24),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationsPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, size: isSmallScreen ? 20 : 24),
            onPressed: _logout,
          ),
        ],
      ),
      drawer: _creerMenu(context, isSmallScreen),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          final bool isOffline = connectivityService.isOffline;
          return SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOffline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Hors ligne - Données locales",
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                _creerTitreSection("Accès rapide", isSmallScreen),
                const SizedBox(height: 16),
                _creerAccesRapide(context, isSmallScreen),
                const SizedBox(height: 24),
                _creerTitreSection("Tableau de bord", isSmallScreen),
                const SizedBox(height: 12),
                _creerStatistiques(isSmallScreen, isOffline),
                const SizedBox(height: 24),
                _creerTitreSection("Météo actuelle", isSmallScreen),
                const SizedBox(height: 12),
                _creerSectionMeteo(isOffline, isSmallScreen),
                const SizedBox(height: 24),
                _creerTitreSection("Membres", isSmallScreen),
                const SizedBox(height: 12),
                _creerListeMembres(isOffline, isSmallScreen),
                const SizedBox(height: 24),
                _creerTitreSection("Récoltes groupées", isSmallScreen),
                const SizedBox(height: 12),
                _creerRecoltesGroupes(userId, isOffline, isSmallScreen),
                const SizedBox(height: 24),
                _creerTitreSection("Suivi des ventes", isSmallScreen),
                const SizedBox(height: 12),
                _creerSectionVentes(isOffline, isSmallScreen),
                const SizedBox(height: 24),
                _creerTitreSection("Suivi des stocks", isSmallScreen),
                const SizedBox(height: 12),
                _creerSectionStocks(userId, isOffline, isSmallScreen),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _creerTitreSection(String titre, bool isSmallScreen) {
    return Text(
      titre,
      style: GoogleFonts.lato(
        fontSize: isSmallScreen ? 18 : 20,
        fontWeight: FontWeight.w800,
        color: Colors.green[900],
      ),
    );
  }

  Widget _creerAccesRapide(BuildContext context, bool isSmallScreen) {
    final boutons = [
      {"icone": Icons.person, "label": "Membres", "page":ListeMembresPage()},
      {"icone": Icons.shopping_cart, "label": "Ventes", "page": VentesCollectivesPage()},
      {"icone": Icons.inventory, "label": "Stocks", "page": StockCooperativePage(cooperativeId: widget.cooperativeId)},
      {"icone": Icons.swap_horiz, "label": "Transactions", "page": PagePaiement(amount: 15000.0 * 1)},
      {"icone": Icons.school, "label": "Formations", "page": FormationsPage()},
      {"icone": Icons.lightbulb_outline, "label": "Conseils", "page": ConseilsPage()},
      {"icone": Icons.agriculture, "label": "Récolte", "page": ListeRecoltePage()},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: boutons.map((bouton) {
          return Padding(
            padding: EdgeInsets.only(right: isSmallScreen ? 12.0 : 16.0),
            child: Column(
              children: [
                IconButton(
                  icon: Icon(bouton['icone'] as IconData, 
                    color: Colors.green[700], 
                    size: isSmallScreen ? 30 : 36),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => bouton['page'] as Widget),
                    );
                  },
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  bouton['label'] as String,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600, 
                    color: Colors.black87,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _creerStatistiques(bool isSmallScreen, bool isOffline) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('cooperatives').doc(widget.cooperativeId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.green));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final hectares = data['hectares']?.toString() ?? 'N/A';
        final rendement = data['rendement']?.toString() ?? 'N/A';

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('membres')
              .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .snapshots(),
          builder: (context, membresSnapshot) {
            if (!membresSnapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: Colors.green));
            }
            final membresCount = membresSnapshot.data!.docs.length;

            return Wrap(
              spacing: isSmallScreen ? 8.0 : 12.0,
              runSpacing: isSmallScreen ? 8.0 : 12.0,
              children: [
                _creerCarteStatistique(Icons.people, "Membres", membresCount.toString(), Colors.green, isSmallScreen),
                _creerCarteStatistique(Icons.terrain, "Superficie", "$hectares ha", Colors.blue, isSmallScreen),
                _creerCarteStatistique(Icons.bar_chart, "Rendement", "$rendement t/ha${isOffline ? ' (local)' : ''}", Colors.orange, isSmallScreen),
              ],
            );
          },
        );
      },
    );
  }

  Widget _creerCarteStatistique(IconData icone, String libelle, String valeur, Color couleur, bool isSmallScreen) {
    return Container(
      width: isSmallScreen ? 90 : 100,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: couleur.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, color: couleur, size: isSmallScreen ? 24 : 28),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(valeur, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: isSmallScreen ? 14 : 16
            )
          ),
          Text(libelle, 
            style: TextStyle(
              color: Colors.grey, 
              fontSize: isSmallScreen ? 10 : 12
            )
          ),
        ],
      ),
    );
  }

  Widget _creerSectionMeteo(bool isOffline, bool isSmallScreen) {
    final donneesMeteo = {
      "temperature": 25.0,
      "conditions": "Ensoleillé",
      "humidite": 60,
      "vent": 10.0,
      "icone": Icons.wb_sunny,
    };
    return Row(
      children: [
        Icon(donneesMeteo['icone'] as IconData, 
          color: Colors.orange, 
          size: isSmallScreen ? 32 : 40),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOffline
                  ? "Météo : Données non disponibles"
                  : "${donneesMeteo['temperature']}°C - ${donneesMeteo['conditions']}",
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
            Text(
              "Humidité: ${donneesMeteo['humidite']}%, Vent: ${donneesMeteo['vent']} km/h",
              style: TextStyle(
                color: Colors.grey,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _creerListeMembres(bool isOffline, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('membres')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.green));
        }
        final membres = snapshot.data!.docs;
        if (membres.isEmpty) {
          return Text(
            isOffline ? "Aucun membre disponible (données locales)" : "Aucun membre disponible",
            style: TextStyle(color: Colors.grey),
          );
        }
        return Column(
          children: membres.map((m) {
            final data = m.data() as Map<String, dynamic>? ?? {};
            final nom = data['nom'] ?? 'Inconnu';
            final statut = data['statut'] ?? 'Inconnu';
            final superficie = data['superficie']?.toString() ?? 'N/A';
            final progression = data['progression']?.toDouble() ?? 0.0;
            return ListTile(
              leading: Icon(Icons.person, color: Colors.green, size: isSmallScreen ? 24 : 28),
              title: Text(nom, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              subtitle: Text("Statut: $statut | Superficie: $superficie ha${isOffline ? ' (local)' : ''}",
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
              trailing: SizedBox(
                width: isSmallScreen ? 30 : 40,
                height: isSmallScreen ? 30 : 40,
                child: CircularProgressIndicator(value: progression, color: Colors.green),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _creerRecoltesGroupes(String? userId, bool isOffline, bool isSmallScreen) {
    if (userId == null) {
      return Text("Utilisateur non connecté.", style: TextStyle(fontSize: isSmallScreen ? 14 : 16));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('recoltesCoop')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.green));
        }
        final recoltes = snapshot.data!.docs;
        if (recoltes.isEmpty) {
          return Text(
            isOffline ? "Aucune récolte disponible (données locales)" : "Aucune récolte disponible",
            style: TextStyle(color: Colors.grey),
          );
        }
        return Column(
          children: recoltes.map((r) {
            final data = r.data() as Map<String, dynamic>? ?? {};
            final produit = data['produit'] ?? 'Inconnu';
            final quantite = data['quantite'] ?? 0;
            final unite = data['unite'] ?? 'kg';
            final date = (data['dateRecolte'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now();
            final couleur = Colors.primaries[recettes.indexOf(produit) % Colors.primaries.length] ??
                const Color.fromARGB(255, 219, 215, 215);
            return Card(
              margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 8),
              color: couleur.withOpacity(0.2),
              child: ListTile(
                leading: Icon(Icons.shopping_basket, color: couleur, size: isSmallScreen ? 24 : 28),
                title: Text(produit, style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
                subtitle: Text("Quantité: $quantite $unite${isOffline ? ' (local)' : ''}",
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                trailing: Text(date.toString().split(' ')[0],
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _creerSectionVentes(bool isOffline, bool isSmallScreen) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('cooperatives')
          .doc(widget.cooperativeId)
          .collection('ventesCollectives')
          .orderBy('dateCreation', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart, color: Color(0xFF2E7D32)),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Text(
                    isOffline ? "Aucune vente récente (données locales)" : "Aucune vente récente",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
        final vente = snapshot.data!.docs.first.data() as Map<String, dynamic>? ?? {};
        final prix = vente['prix']?.toString() ?? 'N/A';
        final date = (vente['dateCreation'] as Timestamp?)?.toDate() ?? DateTime.now();
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.green[800]),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    "Dernière vente : $prix GNF - ${date.toLocal().toString().split(' ')[0]}${isOffline ? ' (local)' : ''}",
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _creerSectionStocks(String? userId, bool isOffline, bool isSmallScreen) {
    if (userId == null) {
      return Text("Utilisateur non connecté.", style: TextStyle(fontSize: isSmallScreen ? 14 : 16));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('cooperatives')
          .doc(widget.cooperativeId)
          .collection('stocksCoop')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Colors.green));
        }
        final stocks = snapshot.data!.docs;
        if (stocks.isEmpty) {
          return Text(
            isOffline ? "Aucun stock disponible (données locales)" : "Aucun stock disponible",
            style: TextStyle(color: Colors.grey),
          );
        }
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warehouse, color: Colors.brown[600]),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Text("Stocks disponibles${isOffline ? ' (local)' : ''}", 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16
                      )
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 8 : 10),
                ...stocks.map((s) {
                  final data = s.data() as Map<String, dynamic>? ?? {};
                  final produit = data['produit'] ?? 'Inconnu';
                  final quantite = data['quantite'] ?? 0;
                  final unite = data['unite'] ?? 'kg';
                  final date = (data['derniereMiseAJour'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now();
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2.0 : 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("$produit : $quantite $unite${isOffline ? ' (local)' : ''}",
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                        Text(date.toString().split(' ')[0],
                          style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _creerMenu(BuildContext context, bool isSmallScreen) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[700]),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_circle, size: isSmallScreen ? 40 : 50, color: Colors.white),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text("Coopérative", 
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: isSmallScreen ? 16 : 18
                  )
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.settings, size: isSmallScreen ? 20 : 24),
            title: Text("Paramètres", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ParametresPage())),
          ),
          ListTile(
            leading: Icon(Icons.help, size: isSmallScreen ? 20 : 24),
            title: Text("Aides", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AidePage())),
          ),
          ListTile(
            leading: Icon(Icons.person, size: isSmallScreen ? 20 : 24),
            title: Text("Profil utilisateur", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UtilisateurProfil())),
          ),
          ListTile(
            leading: Icon(Icons.logout, size: isSmallScreen ? 20 : 24),
            title: Text("Déconnexion", style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }
}

final List<String> recettes = ["Maïs", "Riz", "Manioc"];