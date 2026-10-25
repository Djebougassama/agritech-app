import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SelectionRecoltesPage extends StatefulWidget {
  final String cooperativeId;
  final String produit;
  final String venteId;

  SelectionRecoltesPage({
    required this.cooperativeId,
    required this.produit,
    required this.venteId,
  });

  @override
  _SelectionRecoltesPageState createState() => _SelectionRecoltesPageState();
}

class _SelectionRecoltesPageState extends State<SelectionRecoltesPage> {
  List<DocumentSnapshot> recoltes = [];
  Map<String, bool> selection = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRecoltes();
  }

  Future<void> fetchRecoltes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recoltesCoop')
        .where('cooperativeId', isEqualTo: widget.cooperativeId)
        .where('produit', isEqualTo: widget.produit)
        .get();

    setState(() {
      recoltes = snapshot.docs;
      for (var doc in recoltes) {
        selection[doc.id] = false;
      }
      isLoading = false;
    });
  }

  Future<String> fetchNomMembre(String membreId) async {
    final doc = await FirebaseFirestore.instance.collection('membres').doc(membreId).get();
    return doc.exists ? doc['nom'] ?? 'Inconnu' : 'Inconnu';
  }

  void validerSelection() async {
    final selectedRecoltes = recoltes.where((doc) => selection[doc.id] == true);
    final batch = FirebaseFirestore.instance.batch();

    for (var doc in selectedRecoltes) {
      final venteRef = FirebaseFirestore.instance
          .collection('ventes_groupées')
          .doc(widget.venteId)
          .collection('recoltes_incluses')
          .doc(doc.id);

      batch.set(venteRef, {
        'recolteId': doc.id,
        'membreId': doc['membreId'],
        'produit': doc['produit'],
        'quantite': doc['quantite'],
        'dateRecolte': doc['dateRecolte'],
      });
    }

    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Récoltes ajoutées à la vente groupée.")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Sélection des récoltes"), backgroundColor: Colors.green[700]),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Sélection des récoltes"), backgroundColor: Colors.green[700]),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: recoltes.length,
                itemBuilder: (context, index) {
                  final recolte = recoltes[index];
                  final membreId = recolte['membreId'];
                  final quantite = recolte['quantite'];

                  DateTime date;
                  try {
                    date = (recolte['dateRecolte'] as Timestamp).toDate();
                  } catch (e) {
                    date = DateTime.now();
                  }

                  return FutureBuilder<String>(
                    future: fetchNomMembre(membreId),
                    builder: (context, snapshot) {
                      final nomMembre = snapshot.data ?? membreId;

                      return CheckboxListTile(
                        value: selection[recolte.id] ?? false,
                        onChanged: (bool? val) {
                          setState(() {
                            selection[recolte.id] = val ?? false;
                          });
                        },
                        title: Text("$nomMembre - ${quantite} kg"),
                        subtitle: Text("Récolté le ${DateFormat('dd/MM/yyyy').format(date)}"),
                      );
                    },
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: validerSelection,
              icon: Icon(Icons.check),
              label: Text("Valider la sélection"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
