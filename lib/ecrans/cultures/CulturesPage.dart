import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';
import 'ecran_ajout_culture.dart';
import 'package:agri_tech_app/ecrans/Rapport/rapport_culture.dart';
import 'package:agri_tech_app/modeles/culture.dart';

class CulturesPage extends StatefulWidget {
  @override
  _CulturesPageState createState() => _CulturesPageState();
}

class _CulturesPageState extends State<CulturesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _culturesStream;

  @override
  void initState() {
    super.initState();
    _updateCultureStream();
    _auth.authStateChanges().listen((user) {
      _updateCultureStream();
    });
  }

  void _updateCultureStream() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _culturesStream = _firestore
            .collection('cultures')
            .where('userId', isEqualTo: user.uid)
            .orderBy('datePlantation', descending: true)
            .snapshots();
      });
    } else {
      setState(() {
        _culturesStream = Stream.empty();
      });
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
            return _buildBody(isOffline, baseFontSize, textScaleFactor, screenWidth, basePadding);
          },
        ),
      ),
      appBar: AppBar(
        title: Text(
          'Mes Cultures',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      floatingActionButton: FloatingActionButton(
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
          _navigateToAddCulture(context);
        },
        child: Icon(
          Icons.add,
          size: baseFontSize * 1.5,
        ),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Widget _buildBody(
    bool isOffline,
    double baseFontSize,
    double textScaleFactor,
    double screenWidth,
    double basePadding,
  ) {
    final user = _auth.currentUser;
    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Connectez-vous pour gérer vos cultures',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.9 * textScaleFactor,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: basePadding),
            SizedBox(
              width: screenWidth * 0.6,
              child: ElevatedButton(
                onPressed: () => _auth.signInAnonymously(),
                child: Text(
                  'Se connecter',
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _culturesStream,
      builder: (context, snapshot) {
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Aucune culture enregistrée',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.9 * textScaleFactor,
                color: Colors.grey,
              ),
            ),
          );
        }

        final cultures = snapshot.data!.docs;
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
              child: ElevatedButton.icon(
                onPressed: () {
                  final data = cultures.map((doc) {
                    final cultureData = doc.data() as Map<String, dynamic>;
                    return Culture.fromMap(doc.id, cultureData);
                  }).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RapportCulturePage(cultures: data),
                    ),
                  );
                },
                icon: Icon(Icons.analytics_outlined, size: baseFontSize * 1.2),
                label: Text(
                  'Voir Rapport',
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  minimumSize: Size(screenWidth * 0.9, baseFontSize * 3),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(screenWidth * 0.02),
                itemCount: cultures.length,
                itemBuilder: (context, index) {
                  final doc = cultures[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCultureCard(
                    doc.id,
                    data,
                    isOffline,
                    baseFontSize,
                    textScaleFactor,
                    screenWidth,
                    basePadding,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCultureCard(
    String docId,
    Map<String, dynamic> culture,
    bool isOffline,
    double baseFontSize,
    double textScaleFactor,
    double screenWidth,
    double basePadding,
  ) {
    final datePlantation = (culture['datePlantation'] as Timestamp).toDate();
    final dateRecolte = (culture['dateRecolte'] as Timestamp).toDate();
    final rendement = culture['rendement'] ?? 0;

    return Card(
      margin: EdgeInsets.all(screenWidth * 0.02),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(screenWidth * 0.03),
        leading: Icon(
          Icons.eco,
          color: Colors.green,
          size: baseFontSize * 1.8,
        ),
        title: Text(
          isOffline ? '${culture['nom'] ?? ''} (local)' : culture['nom'] ?? '',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.0 * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: basePadding * 0.5),
            Text(
              isOffline
                  ? 'Type: ${culture['type'] ?? ''} (local)'
                  : 'Type: ${culture['type'] ?? ''}',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
              ),
            ),
            SizedBox(height: basePadding * 0.25),
            Text(
              'Plantation: ${_formatDate(datePlantation)}',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
              ),
            ),
            SizedBox(height: basePadding * 0.25),
            Text(
              'Récolte: ${_formatDate(dateRecolte)}',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
              ),
            ),
            SizedBox(height: basePadding * 0.25),
            Text(
              isOffline
                  ? 'Rendement: $rendement tonnes (local)'
                  : 'Rendement: $rendement tonnes',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.blue,
                size: baseFontSize * 1.2,
              ),
              onPressed: () => _navigateToEditCulture(context, docId, culture),
            ),
            IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.red,
                size: baseFontSize * 1.2,
              ),
              onPressed: () => _confirmDelete(context, docId, isOffline, baseFontSize, textScaleFactor),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddCulture(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AjouterModifierCulturePage()),
    );
  }

  void _navigateToEditCulture(
    BuildContext context,
    String docId,
    Map<String, dynamic> culture,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterModifierCulturePage(
          cultureId: docId,
          cultureData: culture,
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String docId,
    bool isOffline,
    double baseFontSize,
    double textScaleFactor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmer la suppression',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 0.9 * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cette culture ?',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 0.8 * textScaleFactor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _firestore.collection('cultures').doc(docId).delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isOffline
                          ? 'Culture supprimée localement, synchronisation en attente'
                          : 'Culture supprimée avec succès',
                    ),
                    backgroundColor: isOffline ? Colors.orange : Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.8 * textScaleFactor,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}


// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'ecran_ajout_culture.dart';
// import 'package:agri_tech_app/ecrans/Rapport/rapport_culture.dart';
// import 'package:agri_tech_app/modeles/culture.dart';

// class CulturesPage extends StatefulWidget {
//   @override
//   _CulturesPageState createState() => _CulturesPageState();
// }

// class _CulturesPageState extends State<CulturesPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late Stream<QuerySnapshot> _culturesStream;

//   @override
//   void initState() {
//     super.initState();
//     _updateCultureStream();
//     _auth.authStateChanges().listen((user) {
//       _updateCultureStream();
//     });
//   }

//   void _updateCultureStream() {
//     final user = _auth.currentUser;
//     if (user != null) {
//       setState(() {
//         _culturesStream = _firestore
//             .collection('cultures')
//             .where('userId', isEqualTo: user.uid)
//             .orderBy('datePlantation', descending: true)
//             .snapshots();
//       });
//     } else {
//       setState(() {
//         _culturesStream = Stream.empty();
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Mes Cultures', style: GoogleFonts.lato()),
//         backgroundColor: Colors.green.shade700,
//       ),
//       body: _buildBody(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => _navigateToAddCulture(context),
//         child: Icon(Icons.add),
//         backgroundColor: Colors.green.shade700,
//       ),
//     );
//   }

//   Widget _buildBody() {
//     final user = _auth.currentUser;
//     if (user == null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Connectez-vous pour gérer vos cultures'),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => _auth.signInAnonymously(),
//               child: Text('Se connecter'),
//             ),
//           ],
//         ),
//       );
//     }

//     return StreamBuilder<QuerySnapshot>(
//       stream: _culturesStream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) {
//           return Center(child: Text('Erreur de chargement'));
//         }

//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         }

//         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//           return Center(child: Text('Aucune culture enregistrée'));
//         }

//         final cultures = snapshot.data!.docs;

//         return Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ElevatedButton.icon(
//                 onPressed: () {
//                   final data = cultures.map((doc) {
//                   final cultureData = doc.data() as Map<String, dynamic>;
//                   return Culture.fromMap(doc.id, cultureData);
//                 }).toList();
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => RapportCulturePage(cultures: data),
//                     ),
//                   );
//                 },
//                 icon: Icon(Icons.analytics_outlined),
//                 label: Text("Voir Rapport"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green.shade700,
//                   minimumSize: Size(double.infinity, 48),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 padding: EdgeInsets.all(8),
//                 itemCount: cultures.length,
//                 itemBuilder: (context, index) {
//                   final doc = cultures[index];
//                   final data = doc.data() as Map<String, dynamic>;
//                   return _buildCultureCard(doc.id, data);
//                 },
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Widget _buildCultureCard(String docId, Map<String, dynamic> culture) {
//     final datePlantation = (culture['datePlantation'] as Timestamp).toDate();
//     final dateRecolte = (culture['dateRecolte'] as Timestamp).toDate();
//     final rendement = culture['rendement'] ?? 0;

//     return Card(
//       margin: EdgeInsets.all(8),
//       elevation: 3,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: ListTile(
//         contentPadding: EdgeInsets.all(12),
//         leading: Icon(Icons.eco, color: Colors.green, size: 32),
//         title: Text(
//           culture['nom'] ?? '',
//           style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: 6),
//             Text('Type: ${culture['type'] ?? ''}'),
//             SizedBox(height: 4),
//             Text('Plantation: ${_formatDate(datePlantation)}'),
//             SizedBox(height: 4),
//             Text('Récolte: ${_formatDate(dateRecolte)}'),
//             SizedBox(height: 4),
//             Text('Rendement: $rendement tonnes',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               icon: Icon(Icons.edit, color: Colors.blue),
//               onPressed: () => _navigateToEditCulture(context, docId, culture),
//             ),
//             IconButton(
//               icon: Icon(Icons.delete, color: Colors.red),
//               onPressed: () => _confirmDelete(context, docId),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _navigateToAddCulture(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => AjouterModifierCulturePage()),
//     );
//   }

//   void _navigateToEditCulture(
//       BuildContext context, String docId, Map<String, dynamic> culture) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => AjouterModifierCulturePage(
//           cultureId: docId,
//           cultureData: culture,
//         ),
//       ),
//     );
//   }

//   void _confirmDelete(BuildContext context, String docId) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Confirmer la suppression'),
//         content: Text('Voulez-vous vraiment supprimer cette culture ?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Annuler'),
//           ),
//           TextButton(
//             onPressed: () async {
//               try {
//                 await _firestore.collection('cultures').doc(docId).delete();
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Culture supprimée avec succès'),
//                     backgroundColor: Colors.green,
//                   ),
//                 );
//               } catch (e) {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('Erreur lors de la suppression'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: Text('Supprimer', style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('dd/MM/yyyy').format(date);
//   }
// }
