import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/connectivity_service.dart';
import '../../modeles/conseil.dart';
import 'ajout_conseil.dart';

class DetailConseilPage extends StatelessWidget {
  final Conseil conseil;
  final bool isAdmin;

  const DetailConseilPage({
    Key? key,
    required this.conseil,
    required this.isAdmin,
  }) : super(key: key);

  Future<void> _deleteConseil(BuildContext context, bool isOffline, double baseFontSize, double textScaleFactor) async {
    final confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirmer la suppression',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 0.9 * textScaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ce conseil ?',
          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('conseils').doc(conseil.id).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOffline
                  ? 'Conseil supprimé localement, synchronisation en attente'
                  : 'Conseil supprimé avec succès',
            ),
            backgroundColor: isOffline ? Colors.orange : Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Cultures':
        return Icons.eco;
      case 'Engrais':
        return Icons.grass;
      case 'Irrigation':
        return Icons.water_drop;
      case 'Machinerie':
        return Icons.agriculture;
      case 'Protection des Plantes':
        return Icons.health_and_safety;
      case 'Récolte':
        return Icons.shopping_basket;
      default:
        return Icons.lightbulb;
    }
  }

  String _getKeyPoints(String description) {
    final sentences = description.split('. ');
    if (sentences.length > 3) {
      return "- ${sentences[0]}\n- ${sentences[1]}\n- ${sentences[2]}";
    }
    return "- ${sentences.join('\n- ')}";
  }

  @override
Widget build(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
  final double baseFontSize = screenWidth < 360 ? 14 : 16;
  final double basePadding = screenWidth * 0.04;

  final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
  final datePublication = conseil.datePublication;

  return Scaffold(
    body: SafeArea(
      child: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          final bool isOffline = connectivityService.isOffline;
          return SingleChildScrollView(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOffline)
                  Padding(
                    padding: EdgeInsets.only(bottom: basePadding),
                    child: Text(
                      'Hors ligne - Données affichées localement',
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(conseil.categorie),
                      size: baseFontSize * 2.0,
                      color: Colors.green.shade700,
                    ),
                    SizedBox(width: basePadding),
                    Expanded(
                      child: Text(
                        isOffline ? '${conseil.categorie.toUpperCase()} (local)' : conseil.categorie.toUpperCase(),
                        style: GoogleFonts.lato(
                          fontSize: baseFontSize * 0.9 * textScaleFactor,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: basePadding),
                Text(
                  isOffline ? '${conseil.titre} (local)' : conseil.titre,
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 1.2 * textScaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: basePadding * 0.5),
                Text(
                  'Publié le ${dateFormat.format(datePublication)}',
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 0.8 * textScaleFactor,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: basePadding * 1.5),
                Text(
                  isOffline ? '${conseil.description} (local)' : conseil.description,
                  style: GoogleFonts.lato(
                    fontSize: baseFontSize * 0.9 * textScaleFactor,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          );
        },
      ),
    ),
    appBar: AppBar(
      title: Text(
        "Détail du Conseil",
        style: GoogleFonts.lato(
          fontSize: baseFontSize * 1.1 * textScaleFactor,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.green.shade700,
      elevation: 4,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (isAdmin) ...[
          IconButton(
            icon: Icon(
              Icons.edit,
              size: baseFontSize * 1.5,
            ),
            onPressed: () {
              final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
              final bool isOffline = connectivityService.isOffline;
              if (isOffline) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Modification enregistrée localement, synchronisation en attente'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AjoutConseilPage(conseilToEdit: conseil),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.delete,
              size: baseFontSize * 1.5,
            ),
            onPressed: () {
              final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
              final bool isOffline = connectivityService.isOffline;
              _deleteConseil(context, isOffline, baseFontSize, textScaleFactor);
            },
          ),
        ],
      ],
    ),
  );
}
}