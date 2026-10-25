import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ajout_recolte_page.dart';


class ListeRecoltePage extends StatefulWidget {
  @override
  _ListeRecoltePageState createState() => _ListeRecoltePageState();
}

class _ListeRecoltePageState extends State<ListeRecoltePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> getRecoltes() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream.value([]);
  }

  return _firestore
      .collection('recoltesCoop')
      .where('userId', isEqualTo: uid) // <-- Ajout du filtre
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'membreId': doc['membreId'],
        'produit': doc['produit'],
        'quantite': doc['quantite'],
        'dateRecolte': doc['dateRecolte'].toDate(),
      };
    }).toList();
  });
}


  String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liste des Récoltes"),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AjoutRecoltePage(), // ici corrigé
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green[600],
        tooltip: "Ajouter une récolte",
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>( 
        stream: getRecoltes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Aucune récolte enregistrée.", style: TextStyle(fontSize: 16, color: Colors.grey)));
          }

          final recoltes = snapshot.data!;

          return ListView.builder(
            itemCount: recoltes.length,
            itemBuilder: (context, index) {
              final recolte = recoltes[index];

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      recolte['produit'],
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green[800]),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.scale, size: 18, color: Colors.green[700]),
                            SizedBox(width: 6),
                            Text("Quantité : ${recolte['quantite']}", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.green[700]),
                            SizedBox(width: 6),
                            Text("Récolté le : ${formatDate(recolte['dateRecolte'])}", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                    // Lors du clic sur un élément, on redirige vers la page de détail
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/detail_recolte', // Nom de la route de la page de détail
                        arguments: recolte['id'], // ID de la récolte
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


