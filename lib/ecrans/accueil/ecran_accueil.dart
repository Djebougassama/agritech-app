import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agri_tech_app/ecrans/cultures/CulturesPage.dart';
import 'package:agri_tech_app/ecrans/ventes/VentesPage.dart';
import 'package:agri_tech_app/ecrans/Rapport/RapportsPage.dart';
import 'package:agri_tech_app/ecrans/stocks/StocksPage.dart';
import 'package:agri_tech_app/ecrans/formations/ConseilsPage.dart';
import 'package:agri_tech_app/ecrans/formations/FormationsPage.dart';
import 'package:agri_tech_app/ecrans/ventes/TransactionsPage.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Aide_page.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Parametres_page.dart';
import 'package:agri_tech_app/ecrans/barre_latteral/Utilisateur_profil.dart';
import 'package:agri_tech_app/ecrans/Notifications/notifications_page.dart';
import 'package:agri_tech_app/ecrans/accueil/StatistiquePage.dart';
import 'package:agri_tech_app/ecrans/Récolte/RecoltePage.dart';
import 'package:provider/provider.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

void main() {
  runApp(MaterialApp(
    home: PageAccueil(),
  ));
}

class PageAccueil extends StatelessWidget {
  // Mock de l'API météo
  final Map<String, dynamic> mockWeatherData = {
    "temperature": 25.0, // Température en °C
    "conditions": "Ensoleillé",
    "humidity": 60, // Humidité en %
    "windSpeed": 10.0, // Vitesse du vent en km/h
  };

  void _deconnecterUtilisateur(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/connexion'); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la déconnexion : ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.agriculture, color: Colors.white, size: isSmallScreen ? 24 : 30),
            SizedBox(width: isSmallScreen ? 8 : 10),
            Text(
              "AgriTech",
              style: GoogleFonts.lato(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white, size: isSmallScreen ? 20 : 24),
            onPressed: () {
              print("Recherche cliquée");
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white, size: isSmallScreen ? 20 : 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(),
                ),
              );
              print("Notifications cliquées");
            },
          ),
        ],
        backgroundColor: Colors.green.shade700,
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          final bool isOffline = connectivityService.isOffline;
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOffline)
                    Padding(
                      padding: EdgeInsets.only(bottom: isSmallScreen ? 12.0 : 16.0),
                      child: Text(
                        "Hors ligne - Données locales",
                        style: GoogleFonts.lato(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                  // Section Accès rapide (centrée)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          "Accès rapide",
                          style: GoogleFonts.lato(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        Wrap(
                          spacing: isSmallScreen ? 12 : 20,
                          runSpacing: isSmallScreen ? 12 : 20,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildQuickAccessButton("Cultures", Icons.local_florist, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CulturesPage()),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Ventes", Icons.shopping_cart, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ListeVentes()),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Stocks", Icons.inventory, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StocksPage()),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Transactions", Icons.swap_horiz, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => PagePaiement(amount: 15000.0 * 1)),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Formations", Icons.school, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => FormationsPage()),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Conseils", Icons.lightbulb_outline, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => ConseilsPage()),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Rapports", Icons.assignment, () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RapportsPage()),
                              );
                            }, isSmallScreen),
                            _buildQuickAccessButton("Récolte", Icons.agriculture_outlined, () {
                              final currentUser = FirebaseAuth.instance.currentUser;
                              if (currentUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RecoltesPage(userId: currentUser.uid),
                                  ),
                                );
                              }
                            }, isSmallScreen),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Text(
                    "Tableau de bord",
                    style: GoogleFonts.lato(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Graphique adapté pour mobile
                        Container(
                          height: isSmallScreen ? 180 : 250,
                          padding: isSmallScreen ? EdgeInsets.only(top: 10, bottom: 10) : EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FutureBuilder<QuerySnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('cultures')
                                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Text(
                                    isOffline
                                        ? "Aucune donnée de rendement disponible (données locales)"
                                        : "Aucune donnée de rendement disponible",
                                    style: GoogleFonts.lato(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              final cultures = snapshot.data!.docs;
                              final data = cultures.map((doc) {
                                final culture = doc.data() as Map<String, dynamic>;
                                return {
                                  'nom': culture['nom'] ?? 'Culture',
                                  'rendement': culture['rendement']?.toDouble() ?? 0.0,
                                };
                              }).toList();
                              
                              return BarChart(
                                BarChartData(
                                  barGroups: data.asMap().entries.map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: entry.value['rendement'],
                                          color: Colors.green,
                                          width: isSmallScreen ? 12 : 20,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                  titlesData: FlTitlesData(
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Transform.rotate(
                                              angle: -0.5,
                                              child: Text(
                                                data[value.toInt()]['nom'],
                                                style: GoogleFonts.lato(
                                                  fontSize: isSmallScreen ? 8 : 10,
                                                  color: Colors.grey.shade700,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          );
                                        },
                                        reservedSize: isSmallScreen ? 30 : 40,
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: isSmallScreen ? 30 : 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}',
                                            style: GoogleFonts.lato(
                                              fontSize: isSmallScreen ? 8 : 10,
                                              color: Colors.grey.shade700,
                                            ),
                                          );
                                        },
                                        interval: isSmallScreen ? 
                                          (data.isNotEmpty ? data.map((e) => e['rendement']).reduce((a, b) => a > b ? a : b) / 3 : 1) 
                                          : 1,
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    horizontalInterval: isSmallScreen ? 
                                      (data.isNotEmpty ? data.map((e) => e['rendement']).reduce((a, b) => a > b ? a : b) / 3 : 1) 
                                      : 1,
                                  ),
                                  borderData: FlBorderData(show: false),
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipColor: (BarChartGroupData group) => Colors.green.shade700,
                                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                        return BarTooltipItem(
                                          '${data[groupIndex]['nom']}\n${rod.toY.toStringAsFixed(1)} t/ha',
                                          GoogleFonts.lato(color: Colors.white),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatistic("Superficie", "50 ha", isSmallScreen),
                            _buildStatistic("Rendement", "10 t/ha", isSmallScreen),
                            _buildStatistic(
                              "Météo",
                              "${mockWeatherData['temperature']}°C",
                              isSmallScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),
                  Text(
                    "Météo actuelle",
                    style: GoogleFonts.lato(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 10),
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOffline
                              ? "Conditions : Données météo non disponibles (hors ligne)"
                              : "Conditions : ${mockWeatherData['conditions']}",
                          style: GoogleFonts.lato(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 10),
                        Text(
                          "Température : ${mockWeatherData['temperature']}°C",
                          style: GoogleFonts.lato(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 10),
                        Text(
                          "Humidité : ${mockWeatherData['humidity']}%",
                          style: GoogleFonts.lato(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 10),
                        Text(
                          "Vent : ${mockWeatherData['windSpeed']} km/h",
                          style: GoogleFonts.lato(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey.shade700,
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
      bottomNavigationBar: Container(
        height: isSmallScreen ? 60 : 70,
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white, size: isSmallScreen ? 24 : 30),
              onPressed: () {
                print("Accueil cliqué");
              },
            ),
            IconButton(
              icon: Icon(Icons.bar_chart, color: Colors.white, size: isSmallScreen ? 24 : 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatistiquePage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white, size: isSmallScreen ? 24 : 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationsPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.person, color: Colors.white, size: isSmallScreen ? 24 : 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UtilisateurProfil()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green.shade700,
            ),
            child: Text(
              "AgriTech",
              style: GoogleFonts.lato(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person, color: Colors.green.shade700, size: isSmallScreen ? 20 : 24),
            title: Text(
              "Profil utilisateur",
              style: GoogleFonts.lato(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade800,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UtilisateurProfil()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.green.shade700, size: isSmallScreen ? 20 : 24),
            title: Text(
              "Paramètres",
              style: GoogleFonts.lato(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade800,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParametresPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.help, color: Colors.green.shade700, size: isSmallScreen ? 20 : 24),
            title: Text(
              "Aide",
              style: GoogleFonts.lato(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade800,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AidePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.green.shade700, size: isSmallScreen ? 20 : 24),
            title: Text(
              "Déconnexion",
              style: GoogleFonts.lato(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade800,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _deconnecterUtilisateur(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatistic(String label, String value, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(String label, IconData icon, VoidCallback onPressed, bool isSmallScreen) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: isSmallScreen ? 32 : 40, color: Colors.green.shade700),
          onPressed: onPressed,
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: isSmallScreen ? 12 : 14,
            color: Colors.green.shade800,
          ),
        ),
      ],
    );
  }
}

