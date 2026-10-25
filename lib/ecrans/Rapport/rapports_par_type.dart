import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../modeles/rapport.dart';
import '../../services/rapport_service.dart';
import '/../services/connectivity_service.dart';
import 'rapport_details.dart';

class RapportsParTypePage extends StatefulWidget {
  final String utilisateurId;
  final String type;

  const RapportsParTypePage({required this.utilisateurId, required this.type});

  @override
  _RapportsParTypePageState createState() => _RapportsParTypePageState();
}

class _RapportsParTypePageState extends State<RapportsParTypePage> {
  final RapportService _rapportService = RapportService();
  late Future<List<Rapport>> _rapportsFuture;

  @override
  void initState() {
    super.initState();
    _rapportsFuture = _rapportService.getRapportsParType(widget.utilisateurId, widget.type);
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
        title: Text(
          "Rapports de ${widget.type}",
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: baseFontSize * 1.2),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
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
                      'Hors ligne - Données locales',
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                  ),
                Expanded(
                  child: FutureBuilder<List<Rapport>>(
                    future: _rapportsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Erreur: ${snapshot.error}",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(
                            "Aucun rapport trouvé",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.green[700],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(basePadding),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          Rapport rapport = snapshot.data![index];
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: EdgeInsets.symmetric(vertical: basePadding * 0.5),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: basePadding * 1.5,
                                vertical: basePadding,
                              ),
                              title: Text(
                                "Rapport du ${DateFormat('dd/MM/yyyy').format(rapport.dateGeneration)}",
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.9 * textScaleFactor,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[900],
                                ),
                              ),
                              subtitle: Text(
                                rapport.type + (isOffline ? ' (local)' : ''),
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                                  color: Colors.green[700],
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.green[700],
                                size: baseFontSize * 1.2,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RapportDetailsPage(rapport: rapport),
                                  ),
                                );
                              },
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
    );
  }
}