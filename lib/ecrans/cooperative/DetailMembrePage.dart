import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';
import 'edit_membre_page.dart';

class DetailMembrePage extends StatelessWidget {
  final Map<String, dynamic> membre;
  final String docId;

  const DetailMembrePage({Key? key, required this.membre, required this.docId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du membre"),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditMembrePage(
                    membreId: docId,
                    membreData: membre,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          final bool isOffline = connectivityService.isOffline;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isOffline)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      "Hors ligne - Données affichées localement",
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                membre['photo'] != null
                    ? CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(membre['photo']),
                        onBackgroundImageError: (_, __) {},
                      )
                    : const CircleAvatar(
                        radius: 50,
                        child: Icon(Icons.person, size: 40),
                      ),
                const SizedBox(height: 20),
                detailItem("Nom", membre['nom'], icon: Icons.person, isOffline: isOffline),
                detailItem("Sexe", membre['sexe'], icon: Icons.wc, isOffline: isOffline),
                detailItem("Date de naissance", formatDate(membre['date_naissance']), icon: Icons.cake, isOffline: isOffline),
                detailItem("Téléphone", membre['telephone'], icon: Icons.phone, isOffline: isOffline),
                detailItem("Adresse", membre['adresse'], icon: Icons.location_on, isOffline: isOffline),
                detailItem("Culture", membre['culture'], icon: Icons.agriculture, isOffline: isOffline),
                detailItem("Superficie", membre['superficie'] != null ? "${membre['superficie']} ha" : null, icon: Icons.square_foot, isOffline: isOffline),
                detailItem("Statut", membre['statut'], icon: Icons.verified_user, isOffline: isOffline),
                detailItem("Date d’adhésion", formatDate(membre['date_adhesion']), icon: Icons.calendar_today, isOffline: isOffline),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Supprimer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Confirmation"),
                        content: const Text("Voulez-vous vraiment supprimer ce membre ?"),
                        actions: [
                          TextButton(child: const Text("Annuler"), onPressed: () => Navigator.of(ctx).pop(false)),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text("Supprimer"),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          )
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await FirebaseFirestore.instance.collection('membres').doc(docId).delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOffline
                                  ? 'Membre supprimé localement, synchronisation en attente'
                                  : 'Membre supprimé avec succès !',
                            ),
                            backgroundColor: isOffline ? Colors.orange : Colors.green,
                          ),
                        );
                        Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur lors de la suppression : $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget detailItem(String label, dynamic value, {IconData? icon, required bool isOffline}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          if (icon != null) Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  isOffline ? "${value?.toString() ?? "Non défini"} (local)" : value?.toString() ?? "Non défini",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? formatDate(dynamic rawDate) {
    if (rawDate == null) return null;
    try {
      DateTime date;
      if (rawDate is String) {
        date = DateTime.parse(rawDate);
      } else if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is DateTime) {
        date = rawDate;
      } else {
        return rawDate.toString();
      }
      return DateFormat("d MMMM yyyy", 'fr_FR').format(date);
    } catch (e) {
      return rawDate.toString();
    }
  }
}