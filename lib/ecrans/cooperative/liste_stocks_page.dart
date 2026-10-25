import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:agri_tech_app/modeles/stockCoop.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class StockCooperativePage extends StatefulWidget {
  final String cooperativeId;

  const StockCooperativePage({required this.cooperativeId, Key? key})
      : super(key: key);

  @override
  _StockCooperativePageState createState() => _StockCooperativePageState();
}

class _StockCooperativePageState extends State<StockCooperativePage> {
  final TextEditingController produitController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  String? stockIdToEdit;
  String? selectedUnite;
  final List<String> uniteOptions = ['kg', 'tonnes', 'caisses', 'sacs'];

  @override
  void initState() {
    super.initState();
    selectedUnite = uniteOptions[0];
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double basePadding = screenWidth * 0.04; // 4% de la largeur
    final double baseFontSize = screenWidth < 360 ? 14 : 16; // Police de base

    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return SingleChildScrollView(
              padding: EdgeInsets.all(basePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  _creerSectionTitre("Stocks actuels", baseFontSize, textScaleFactor),
                  _creerListeStocks(isOffline, baseFontSize, textScaleFactor, screenWidth),
                  SizedBox(height: basePadding * 1.5),
                  _creerSectionTitre("Ajouter/Modifier un stock", baseFontSize, textScaleFactor),
                  _creerFormulaireStock(isOffline, baseFontSize, textScaleFactor, screenWidth),
                ],
              ),
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.code, color: Colors.white, size: 24),
            SizedBox(width: basePadding * 0.5),
            Text(
              "Gestion des Stocks",
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: baseFontSize * 1.1 * textScaleFactor,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _creerSectionTitre(String titre, double baseFontSize, double textScaleFactor) {
    return Text(
      titre,
      style: GoogleFonts.lato(
        fontSize: baseFontSize * 1.25 * textScaleFactor, // 20-22 sp
        fontWeight: FontWeight.w800,
        color: Colors.green[900],
      ),
    );
  }

  Widget _creerListeStocks(bool isOffline, double baseFontSize, double textScaleFactor, double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cooperatives')
          .doc(widget.cooperativeId)
          .collection('stocksCoop')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }
        if (snapshot.hasError) {
          debugPrint("Erreur de chargement: ${snapshot.error}");
          return Text(
            "Erreur de chargement",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              color: Colors.red,
            ),
          );
        }
        final stocks = snapshot.data?.docs
                .map((doc) => Stock.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
                .toList() ??
            [];
        debugPrint("Stocks trouvés: ${stocks.length}");
        if (stocks.isEmpty) {
          return Text(
            isOffline ? "Aucun stock disponible (données locales)." : "Aucun stock disponible.",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              color: Colors.grey,
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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stocks.length,
          itemBuilder: (context, index) {
            final stock = stocks[index];
            return Card(
              color: Colors.green[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenWidth * 0.02),
                leading: Icon(Icons.local_florist, color: Colors.green, size: baseFontSize * 1.5),
                title: Text(
                  isOffline ? "${stock.produit} (local)" : stock.produit,
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[800],
                  ),
                ),
                subtitle: Text(
                  isOffline
                      ? "${stock.quantite} ${stock.unite} (local) - Mise à jour: ${stock.derniereMiseAJour.toLocal()}"
                      : "${stock.quantite} ${stock.unite} - Mise à jour: ${stock.derniereMiseAJour.toLocal()}",
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 0.8 * textScaleFactor,
                    color: Colors.grey[700],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      iconSize: baseFontSize * 1.2,
                      onPressed: () => _ouvrirFormulaireModification(stock),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      iconSize: baseFontSize * 1.2,
                      onPressed: () => _supprimerStock(stock.id, isOffline),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _ouvrirFormulaireModification(Stock stock) {
    setState(() {
      stockIdToEdit = stock.id;
      produitController.text = stock.produit;
      quantiteController.text = stock.quantite.toString();
      selectedUnite = stock.unite;
    });
  }

  Widget _creerFormulaireStock(bool isOffline, double baseFontSize, double textScaleFactor, double screenWidth) {
    return Card(
      color: Colors.green[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          children: [
            TextField(
              controller: produitController,
              decoration: InputDecoration(
                labelText: isOffline ? "Produit (local)" : "Produit",
                labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                prefixIcon: const Icon(Icons.local_grocery_store, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
            ),
            SizedBox(height: screenWidth * 0.03),
            TextField(
              controller: quantiteController,
              decoration: InputDecoration(
                labelText: isOffline ? "Quantité (local)" : "Quantité",
                labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                prefixIcon: const Icon(Icons.numbers, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              keyboardType: TextInputType.number,
              style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
            ),
            SizedBox(height: screenWidth * 0.03),
            DropdownButtonFormField<String>(
              value: selectedUnite,
              decoration: InputDecoration(
                labelText: isOffline ? "Unité (local)" : "Unité",
                labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                prefixIcon: const Icon(Icons.scale, color: Colors.green),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: uniteOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedUnite = newValue;
                });
              },
            ),
            SizedBox(height: screenWidth * 0.04),
            SizedBox(
              width: screenWidth * 0.9,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03, horizontal: screenWidth * 0.06),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final quantite = int.tryParse(quantiteController.text);
                  if (produitController.text.isEmpty || quantite == null || quantite <= 0 || selectedUnite == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Veuillez remplir tous les champs correctement")),
                    );
                    return;
                  }
                  final stock = Stock(
                    id: stockIdToEdit ?? DateTime.now().millisecondsSinceEpoch.toString(),
                    cooperativeId: widget.cooperativeId,
                    derniereMiseAJour: DateTime.now(),
                    produit: produitController.text,
                    quantite: quantite,
                    unite: selectedUnite!,
                  );
                  _enregistrerStock(stock, isOffline);
                  produitController.clear();
                  quantiteController.clear();
                  setState(() {
                    stockIdToEdit = null;
                    selectedUnite = uniteOptions[0];
                  });
                },
                child: Text(
                  stockIdToEdit == null ? "Ajouter" : "Mettre à jour",
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enregistrerStock(Stock stock, bool isOffline) async {
    try {
      await FirebaseFirestore.instance
          .collection('cooperatives')
          .doc(widget.cooperativeId)
          .collection('stocksCoop')
          .doc(stock.id)
          .set(stock.toMap(), SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Stock enregistré localement, synchronisation en attente"
                : "Stock synchronisé avec succès",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  Future<void> _supprimerStock(String stockId, bool isOffline) async {
    try {
      await FirebaseFirestore.instance
          .collection('cooperatives')
          .doc(widget.cooperativeId)
          .collection('stocksCoop')
          .doc(stockId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Stock supprimé localement, synchronisation en attente"
                : "Stock supprimé avec succès",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }

  @override
  void dispose() {
    produitController.dispose();
    quantiteController.dispose();
    super.dispose();
  }
}