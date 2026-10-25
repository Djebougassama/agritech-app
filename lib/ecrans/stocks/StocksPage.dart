import 'package:flutter/material.dart';
import 'package:agri_tech_app/ecrans/stocks/ecran_ajout_stock.dart';
import 'package:agri_tech_app/ecrans/Rapport/rapport_stock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class StocksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Gestion des stocks",
          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            tooltip: 'Voir Rapport',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RapportStockPage(),
                ),
              );
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stocks')
            .where('userId', isEqualTo: currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Aucun stock trouvé",
                style: GoogleFonts.lato(fontSize: 18),
              ),
            );
          }

          final stocks = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: stocks.length,
            itemBuilder: (context, index) {
              final stock = stocks[index].data() as Map<String, dynamic>;

              final produit = (stock['produit'] ?? stock['Produit'])?.toString() ?? 'Produit inconnu';
              final quantite = stock['quantite'] as int? ?? 0;
              final dateAjout = stock['dateAjout'];
              final date = dateAjout is Timestamp ? dateAjout.toDate() : null;

              return Card(
                elevation: 5,
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(Icons.inventory,
                      color: Colors.green.shade700, size: 40),
                  title: Text(
                      (stock['produit'] ?? stock['Produit'])?.toString() ?? 'Produit inconnu',
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      quantite == 0
                          ? Row(
                              children: [
                                Text("Stock épuisé",
                                    style: TextStyle(
                                        color: Colors.red, fontSize: 14)),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    _afficherDialogueReapprovisionnement(
                                      context,
                                      stocks[index].id,
                                      quantite,
                                      produit,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: Text("Réapprovisionner",
                                      style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            )
                          : Text("Quantité : $quantite",
                              style: GoogleFonts.lato(fontSize: 14)),
                      Text("Date d'ajout : ${date != null ? _formatDate(date) : 'Date inconnue'}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.green.shade700),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AjouterModifierStockPage(
                                stockId: stocks[index].id,
                                stockData: stock,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          FirebaseFirestore.instance
                              .collection('stocks')
                              .doc(stocks[index].id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AjouterModifierStockPage(),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  void _afficherDialogueReapprovisionnement(BuildContext context,
      String stockId, int ancienneQuantite, String produit) {
    TextEditingController _qteController = TextEditingController();
    final currentUser = FirebaseAuth.instance.currentUser;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Réapprovisionner le stock"),
          content: TextField(
            controller: _qteController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Quantité à ajouter"),
          ),
          actions: [
            TextButton(
              child: Text("Annuler"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: Text("Valider"),
              onPressed: () async {
                int nouvelleQuantite = int.tryParse(_qteController.text) ?? 0;

                if (nouvelleQuantite > 0) {
                  final now = DateTime.now();

                  await FirebaseFirestore.instance
                      .collection('stocks')
                      .doc(stockId)
                      .update({
                    'quantite': ancienneQuantite + nouvelleQuantite,
                  });

                  await FirebaseFirestore.instance
                      .collection('approvisionnements')
                      .add({
                    'stockId': stockId,
                    'produit': produit,
                    'quantiteAjoutee': nouvelleQuantite,
                    'dateApprovisionnement': now,
                    'userId': currentUser?.uid,
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Stock réapprovisionné avec succès")),
                  );
                }
              },
            )
          ],
        );
      },
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import '../../services/connectivity_service.dart';
// import './ecran_ajout_stock.dart';
// import '../Rapport/rapport_stock.dart';

// class StocksPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     final currentUser = FirebaseAuth.instance.currentUser;
//     final double screenWidth = MediaQuery.of(context).size.width;
//     final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
//     final double baseFontSize = screenWidth < 360 ? 14 : 16;
//     final double basePadding = screenWidth * 0.04;

//     return Scaffold(
//       backgroundColor: Colors.green[100],
//       appBar: AppBar(
//         title: Text(
//           "Gestion des stocks",
//           style: GoogleFonts.lato(
//             fontSize: baseFontSize * 1.1 * textScaleFactor,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.green[700],
//         actions: [
//           IconButton(
//             icon: Icon(Icons.picture_as_pdf, size: baseFontSize * 1.5, color: Colors.white),
//             tooltip: 'Voir Rapport',
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => RapportStockPage()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Consumer<ConnectivityService>(
//           builder: (context, connectivityService, child) {
//             final bool isOffline = connectivityService.isOffline;
//             return Column(
//               children: [
//                 if (isOffline)
//                   Padding(
//                     padding: EdgeInsets.all(basePadding),
//                     child: Text(
//                       'Hors ligne - Données affichées localement',
//                       style: GoogleFonts.lato(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.bold,
//                         fontSize: baseFontSize * 0.9 * textScaleFactor,
//                       ),
//                     ),
//                   ),
//                 Expanded(
//                   child: StreamBuilder<QuerySnapshot>(
//                     stream: FirebaseFirestore.instance
//                         .collection('stocks')
//                         .where('userId', isEqualTo: currentUser?.uid)
//                         .snapshots(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return Center(child: CircularProgressIndicator(color: Colors.green));
//                       }

//                       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                         return Center(
//                           child: Text(
//                             "Aucun stock trouvé",
//                             style: GoogleFonts.lato(
//                               fontSize: baseFontSize * 0.9 * textScaleFactor,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         );
//                       }

//                       final stocks = snapshot.data!.docs;

//                       return ListView.builder(
//                         padding: EdgeInsets.all(basePadding),
//                         itemCount: stocks.length,
//                         itemBuilder: (context, index) {
//                           final stock = stocks[index].data() as Map<String, dynamic>;
//                           final produit = (stock['produit'] ?? stock['Produit'])?.toString() ?? 'Produit inconnu';
//                           final quantite = stock['quantite'] as int? ?? 0;
//                           final dateAjout = stock['dateAjout'];
//                           final date = dateAjout is Timestamp ? dateAjout.toDate() : null;

//                           return Card(
//                             elevation: 5,
//                             margin: EdgeInsets.only(bottom: basePadding),
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//                             child: ListTile(
//                               contentPadding: EdgeInsets.all(basePadding),
//                               leading: Icon(
//                                 Icons.inventory,
//                                 color: Colors.green[800],
//                                 size: baseFontSize * 2,
//                               ),
//                               title: Text(
//                                 produit + (isOffline ? ' (local)' : ''),
//                                 style: GoogleFonts.lato(
//                                   fontSize: baseFontSize * 0.9 * textScaleFactor,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               subtitle: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   SizedBox(height: basePadding * 0.5),
//                                   quantite == 0
//                                       ? Row(
//                                           children: [
//                                             Text(
//                                               "Stock épuisé",
//                                               style: GoogleFonts.lato(
//                                                 color: Colors.red,
//                                                 fontSize: baseFontSize * 0.8 * textScaleFactor,
//                                               ),
//                                             ),
//                                             SizedBox(width: basePadding),
//                                             ElevatedButton(
//                                               onPressed: () {
//                                                 _afficherDialogueReapprovisionnement(
//                                                   context,
//                                                   stocks[index].id,
//                                                   quantite,
//                                                   produit,
//                                                   isOffline,
//                                                   baseFontSize,
//                                                   textScaleFactor,
//                                                   basePadding,
//                                                 );
//                                               },
//                                               style: ElevatedButton.styleFrom(
//                                                 backgroundColor: Colors.green[700],
//                                                 padding: EdgeInsets.symmetric(
//                                                   horizontal: basePadding,
//                                                   vertical: basePadding * 0.5,
//                                                 ),
//                                               ),
//                                               child: Text(
//                                                 "Réapprovisionner",
//                                                 style: GoogleFonts.lato(
//                                                   fontSize: baseFontSize * 0.7 * textScaleFactor,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         )
//                                       : Text(
//                                           "Quantité : ${stock}",
//                                           style: GoogleFonts.lato(
//                                             fontSize: baseFontSize * 0.8 * textScaleFactor,
//                                           ),
//                                         ),
//                                   Text(
//                                     "Date d’ajout : ${date != null ? _formatDate(date) : 'Date inconnue'}",
//                                     style: GoogleFonts.lato(
//                                       fontSize: baseFontSize * 0.8 * textScaleFactor,
//                                       color: Colors.grey[600],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               trailing: Row(
//                                 mainAxisSize: MainAxisSize.min,
//                                 children: [
//                                   IconButton(
//                                     icon: Icon(
//                                       Icons.edit,
//                                       color: Colors.green[700],
//                                       size: baseFontSize * 1.2,
//                                     ),
//                                     onPressed: () {
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) => AjouterModifierStockPage(
//                                             stockId: stocks[index].id,
//                                             stockData: stock,
//                                           ),
//                                         ),
//                                       );
//                                     },
//                                   ),
//                                   IconButton(
//                                     icon: Icon(
//                                       Icons.delete,
//                                       color: Colors.red,
//                                       size: baseFontSize * 1.2,
//                                     ),
//                                     onPressed: () async {
//                                       try {
//                                         await FirebaseFirestore.instance
//                                             .collection('stocks')
//                                             .doc(stocks[index].id)
//                                             .delete();
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           SnackBar(
//                                             content: Text(
//                                               isOffline
//                                                   ? "Suppression enregistrée localement, synchronisation en attente"
//                                                   : "Stock supprimé avec succès",
//                                             ),
//                                             backgroundColor: isOffline ? Colors.orange : Colors.green,
//                                           ),
//                                         );
//                                       } catch (e) {
//                                         print("Erreur lors de la suppression: $e");
//                                         ScaffoldMessenger.of(context).showSnackBar(
//                                           SnackBar(
//                                             content: Text("Erreur: $e"),
//                                             backgroundColor: Colors.red,
//                                           ),
//                                         );
//                                       }
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (_) => AjouterModifierStockPage()),
//           );
//         },
//         child: Icon(Icons.add, size: baseFontSize * 1.5, color: Colors.white),
//         backgroundColor: Colors.green[700],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
//   }

//   void _afficherDialogueReapprovisionnement(
//     BuildContext context,
//     String stockId,
//     int ancienneQuantite,
//     String produit,
//     bool isOffline,
//     double baseFontSize,
//     double textScaleFactor,
//     double basePadding,
//   ) {
//     final TextEditingController _qteController = TextEditingController();
//     final currentUser = FirebaseAuth.instance.currentUser;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         title: Text(
//           "Réapprovisionner le stock",
//           style: GoogleFonts.lato(
//             fontSize: baseFontSize * 0.9 * textScaleFactor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         content: TextFormField(
//           controller: _qteController,
//           keyboardType: TextInputType.number,
//           decoration: InputDecoration(
//             labelText: "Quantité à ajouter",
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//             filled: true,
//             fillColor: Colors.green[50],
//             labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
//           ),
//           style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
//         ),
//         actions: [
//           TextButton(
//             child: Text(
//               "Annuler",
//               style: GoogleFonts.lato(
//                 fontSize: baseFontSize * 0.8 * textScaleFactor,
//                 color: Colors.grey[600],
//               ),
//             ),
//             onPressed: () => Navigator.pop(context),
//           ),
//           ElevatedButton(
//             child: Text(
//               "Valider",
//               style: GoogleFonts.lato(
//                 fontSize: baseFontSize * 0.8 * textScaleFactor,
//                 color: Colors.white,
//               ),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green[700],
//               padding: EdgeInsets.symmetric(horizontal: basePadding * 2, vertical: basePadding),
//             ),
//             onPressed: () async {
//               final nouvelleQuantite = int.tryParse(_qteController.text) ?? 0;
//               if (nouvelleQuantite <= 0) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text("Veuillez entrer une quantité valide"),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//                 return;
//               }

//               try {
//                 final now = DateTime.now();
//                 await FirebaseFirestore.instance.collection('stocks').doc(stockId).update({
//                   'quantite': ancienneQuantite + nouvelleQuantite,
//                   'isSynced': !isOffline,
//                 });

//                 await FirebaseFirestore.instance.collection('approvisionnements').add({
//                   'stockId': stockId,
//                   'produit': produit,
//                   'quantiteAjoutee': nouvelleQuantite,
//                   'dateAjout': Timestamp.fromDate(now),
//                   'userId': currentUser?.uid,
//                   'isSynced': !isOffline,
//                 });

//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       isOffline
//                           ? "Réapprovisionnement enregistré localement, synchronisation en attente"
//                           : "Stock réapprovisionné avec succès",
//                     ),
//                     backgroundColor: isOffline ? Colors.orange : Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 print("Erreur lors du réapprovisionnement: $e");
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text("Erreur: $e"),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }