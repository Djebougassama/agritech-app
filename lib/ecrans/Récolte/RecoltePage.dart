import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';

class RecoltesPage extends StatelessWidget {
  final String userId;

  const RecoltesPage({super.key, required this.userId});

  void _showEditDialog(
    BuildContext context,
    String recolteId,
    Map<String, dynamic> data,
    bool isOffline,
    double baseFontSize,
    double textScaleFactor,
    double basePadding,
  ) {
    final nomCultureController = TextEditingController(text: data['nomCulture']);
    final quantiteController = TextEditingController(text: data['quantite']?.toString() ?? '');
    final uniteController = TextEditingController(text: data['unite'] ?? 'kg');
    DateTime selectedDate = (data['dateRecolte'] as Timestamp?)?.toDate() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            "Modifier la récolte",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomCultureController,
                  decoration: InputDecoration(
                    labelText: "Nom de la culture",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.green[50],
                    labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                  style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                ),
                SizedBox(height: basePadding),
                TextFormField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Quantité",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.green[50],
                    labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                  style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                ),
                SizedBox(height: basePadding),
                TextFormField(
                  controller: uniteController,
                  decoration: InputDecoration(
                    labelText: "Unité",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.green[50],
                    labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                  style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                ),
                SizedBox(height: basePadding),
                Row(
                  children: [
                    Text(
                      "Date : ",
                      style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          selectedDate = picked;
                        }
                      },
                      child: Text(
                        "${selectedDate.day.toString().padLeft(2, '0')}/"
                        "${selectedDate.month.toString().padLeft(2, '0')}/"
                        "${selectedDate.year}",
                        style: GoogleFonts.lato(
                          fontSize: baseFontSize * 0.8 * textScaleFactor,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                "Annuler",
                style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: EdgeInsets.symmetric(horizontal: basePadding * 2, vertical: basePadding),
              ),
              child: Text(
                "Enregistrer",
                style: GoogleFonts.lato(
                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                  color: Colors.white,
                ),
              ),
              onPressed: () async {
                try {
                  final quantite = double.tryParse(quantiteController.text) ?? 0;
                  if (quantite <= 0 || nomCultureController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text("Veuillez entrer des données valides"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await FirebaseFirestore.instance.collection('recoltes').doc(recolteId).update({
                    'nomCulture': nomCultureController.text.trim(),
                    'quantite': quantite,
                    'unite': uniteController.text.trim(),
                    'dateRecolte': Timestamp.fromDate(selectedDate),
                    'userId': userId,
                    'isSynced': !isOffline,
                  });

                  if (!isOffline) {
                    // Hypothetical notification
                    // await ServiceNotifications.notifyRecolteUpdate(
                    //   userId: userId,
                    //   nomCulture: nomCultureController.text.trim(),
                    //   quantite: quantite,
                    //   unite: uniteController.text.trim(),
                    // );
                  } else {
                    await FirebaseFirestore.instance.collection('pending_notifications').add({
                      'type': 'recolte_update',
                      'userId': userId,
                      'nomCulture': nomCultureController.text.trim(),
                      'quantite': quantite,
                      'unite': uniteController.text.trim(),
                      'timestamp': Timestamp.now(),
                    });
                  }

                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isOffline
                            ? "Modification enregistrée localement, synchronisation en attente"
                            : "Récolte modifiée avec succès",
                      ),
                      backgroundColor: isOffline ? Colors.orange : Colors.green,
                    ),
                  );
                } catch (e) {
                  print("Erreur lors de la modification: $e");
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text("Erreur: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showOptionsDialog(
    BuildContext context,
    String recolteId,
    Map<String, dynamic> data,
    bool isOffline,
    double baseFontSize,
    double textScaleFactor,
    double basePadding,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: basePadding * 2, horizontal: basePadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.green[700], size: baseFontSize * 1.2),
                  title: Text(
                    "Modifier",
                    style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(
                      context,
                      recolteId,
                      data,
                      isOffline,
                      baseFontSize,
                      textScaleFactor,
                      basePadding,
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red, size: baseFontSize * 1.2),
                  title: Text(
                    "Supprimer",
                    style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        title: Text(
                          "Confirmer la suppression",
                          style: GoogleFonts.lato(
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          "Voulez-vous vraiment supprimer cette récolte ?",
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                        ),
                        actions: [
                          TextButton(
                            child: Text(
                              "Annuler",
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          TextButton(
                            child: Text(
                              "Supprimer",
                              style: GoogleFonts.lato(
                                fontSize: baseFontSize * 0.8 * textScaleFactor,
                                color: Colors.red,
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await FirebaseFirestore.instance.collection('recoltes').doc(recolteId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOffline
                                  ? "Suppression enregistrée localement, synchronisation en attente"
                                  : "Récolte supprimée avec succès",
                            ),
                            backgroundColor: isOffline ? Colors.orange : Colors.green,
                          ),
                        );
                      } catch (e) {
                        print("Erreur lors de la suppression: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erreur: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text(
          "Mes Récoltes",
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 6,
      ),
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
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('recoltes')
                        .where('userId', isEqualTo: userId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.green),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            "Aucune récolte trouvée.",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }

                      final recoltes = snapshot.data!.docs;

                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: basePadding, vertical: basePadding),
                        itemCount: recoltes.length,
                        itemBuilder: (context, index) {
                          final doc = recoltes[index];
                          final data = doc.data() as Map<String, dynamic>;

                          String dateText = '';
                          if (data['dateRecolte'] != null && data['dateRecolte'] is Timestamp) {
                            final date = (data['dateRecolte'] as Timestamp).toDate();
                            dateText = "${date.day.toString().padLeft(2, '0')}/"
                                "${date.month.toString().padLeft(2, '0')}/"
                                "${date.year}";
                          } else if (data['date'] != null) {
                            dateText = data['date'].toString();
                          }

                          final quantite = data['quantite']?.toString() ?? '';
                          final unite = data['unite'] ?? 'kg';

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: basePadding),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: basePadding * 1.5,
                                vertical: basePadding,
                              ),
                              leading: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green[100],
                                ),
                                padding: EdgeInsets.all(basePadding),
                                child: Icon(
                                  Icons.agriculture,
                                  color: Colors.green[700],
                                  size: baseFontSize * 1.5,
                                ),
                              ),
                              title: Text(
                                "${data['nomCulture'] ?? 'Culture inconnue'}${isOffline ? ' (local)' : ''}",
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.9 * textScaleFactor,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[900],
                                ),
                              ),
                              subtitle: Padding(
                                padding: EdgeInsets.only(top: basePadding * 0.5),
                                child: Text(
                                  "Quantité : $quantite $unite\nDate : $dateText",
                                  style: GoogleFonts.lato(
                                    fontSize: baseFontSize * 0.8 * textScaleFactor,
                                    height: 1.4,
                                    color: Colors.green[800],
                                  ),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.green[700],
                                  size: baseFontSize * 1.2,
                                ),
                                onPressed: () {
                                  _showOptionsDialog(
                                    context,
                                    doc.id,
                                    data,
                                    isOffline,
                                    baseFontSize,
                                    textScaleFactor,
                                    basePadding,
                                  );
                                },
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green[700],
        onPressed: () {
          Navigator.pushNamed(context, '/AjouterRecoltesPage', arguments: userId);
        },
        child: Icon(
          Icons.add,
          size: baseFontSize * 1.5,
          color: Colors.white,
        ),
        tooltip: 'Ajouter une récolte',
      ),
    );
  }
}