import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class StatistiquePage extends StatefulWidget {
  const StatistiquePage({Key? key}) : super(key: key);

  @override
  State<StatistiquePage> createState() => _StatistiquePageState();
}

class _StatistiquePageState extends State<StatistiquePage> {
  int totalVentes = 0;
  double montantTotalVentes = 0;
  List<Map<String, dynamic>> topProduits = [];

  int totalProduitsStock = 0;
  int totalCultures = 0;
  int totalUtilisateurs = 0;
  int totalFormations = 0;
  int totalConseils = 0;

  Map<int, double> ventesParMois = {};

  @override
  void initState() {
    super.initState();
    chargerStatistiques();
  }

  Future<void> chargerStatistiques() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final ventesSnap = await FirebaseFirestore.instance
        .collection('ventes')
        .where('userId', isEqualTo: userId)
        .get();

    final stockSnap = await FirebaseFirestore.instance
        .collection('stocks')
        .where('userId', isEqualTo: userId)
        .get();

    final culturesSnap = await FirebaseFirestore.instance
        .collection('cultures')
        .where('userId', isEqualTo: userId)
        .get();

    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final formationsSnap = await FirebaseFirestore.instance.collection('formations').get();
    final conseilsSnap = await FirebaseFirestore.instance.collection('conseils').get();

    double totalMontant = 0;
    Map<String, int> produitsCount = {};
    Map<int, double> moisVentes = {};

    for (var doc in ventesSnap.docs) {
      final data = doc.data();
      final montant = (data['prixUnitaire'] ?? 0) * (data['quantite'] ?? 0);
      final produit = data['produit'] ?? 'Inconnu';
      final date = (data['dateVente'] as Timestamp?)?.toDate();

      totalMontant += montant;
      produitsCount[produit] = (produitsCount[produit] ?? 0) + 1;

      if (date != null) {
        final mois = date.month;
        moisVentes[mois] = (moisVentes[mois] ?? 0) + montant;
      }
    }

    final sortedProduits = produitsCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sortedProduits.take(5).map((e) => {'produit': e.key, 'quantite': e.value}).toList();

    int totalQuantiteStocks = 0;
    for (var doc in stockSnap.docs) {
      final data = doc.data();
      final quantite = data['quantite'] ?? 0;
      totalQuantiteStocks += (quantite as num).toInt();
    }

    setState(() {
      totalVentes = ventesSnap.size;
      montantTotalVentes = totalMontant;
      topProduits = top5;
      ventesParMois = moisVentes;

      totalProduitsStock = totalQuantiteStocks;
      totalCultures = culturesSnap.size;
      totalUtilisateurs = usersSnap.size;
      totalFormations = formationsSnap.size;
      totalConseils = conseilsSnap.size;
    });
  }

  String formatMontant(double montant) {
    final format = NumberFormat.currency(locale: 'fr_FR', symbol: 'GNF', decimalDigits: 0);
    return format.format(montant);
  }

  Widget buildCard(String title, String value, IconData icon, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color ?? Colors.white,
        border: Border(left: BorderSide(color: Colors.green.shade600, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.green.shade600),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTopProduits() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Top 5 Produits Vendus",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...topProduits.map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text(p['produit'], style: const TextStyle(fontSize: 16))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("x${p['quantite']}",
                        style: TextStyle(color: Colors.green.shade800)),
                  )
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget buildGraphiqueMensuel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Évolution mensuelle des ventes",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const mois = [
                            '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
                            'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
                          ];
                          return Text(mois[value.toInt()]);
                        },
                        interval: 1,
                      ),
                    ),
                  ),
                  barGroups: ventesParMois.entries.map((e) {
                    return BarChartGroupData(x: e.key, barRods: [
                      BarChartRodData(toY: e.value, color: Colors.green, width: 16),
                    ]);
                  }).toList(),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Statistiques Globales', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildCard("Total des ventes", "$totalVentes", Icons.point_of_sale),
            buildCard("Montant total", formatMontant(montantTotalVentes), Icons.monetization_on),
            buildTopProduits(),
            buildGraphiqueMensuel(),
            buildCard("Quantité totale en stock", "$totalProduitsStock", Icons.inventory),
            buildCard("Cultures enregistrées", "$totalCultures", Icons.agriculture),
            // buildCard("Utilisateurs", "$totalUtilisateurs", Icons.people),
            buildCard("Formations", "$totalFormations", Icons.school),
            buildCard("Conseils", "$totalConseils", Icons.lightbulb),
          ],
        ),
      ),
    );
  }
}


