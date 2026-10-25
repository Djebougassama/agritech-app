import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/../services/connectivity_service.dart';

class RapportVentePage extends StatefulWidget {
  const RapportVentePage({Key? key}) : super(key: key);

  @override
  _RapportVentePageState createState() => _RapportVentePageState();
}

class _RapportVentePageState extends State<RapportVentePage> {
  late Future<Uint8List> _futurePdf;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _futurePdf = _generatePdf();
  }

  Future<List<Map<String, dynamic>>> _fetchVentes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Utilisateur non connecté !");
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('ventes')
        .where('userId', isEqualTo: user.uid)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();
  }

  Future<Uint8List> _generatePdf() async {
    final ventes = await _fetchVentes();
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final currentDate = dateFormatter.format(DateTime.now());
    final ByteData logoData = await rootBundle.load('assets/logo_agritech.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);
    final lato = await PdfGoogleFonts.latoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 1 * PdfPageFormat.cm),
          child: pw.Text('Généré le : $currentDate',
              style: pw.TextStyle(font: lato, fontSize: 10, color: PdfColors.grey700)),
        ),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logoImage, height: 60),
                pw.Text("AgriTech",
                    style: pw.TextStyle(
                        font: lato, fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text(" Rapport des Ventes",
                  style: pw.TextStyle(font: lato, fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Produit', 'Quantité', 'Prix Unitaire (GNF)', 'Date Vente'],
              data: ventes.map((vente) {
                return [
                  vente['produit'] ?? '',
                  '${vente['quantite'] ?? 0}',
                  '${vente['prixUnitaire'] ?? 0}',
                  vente['dateVente'] != null
                      ? dateFormatter.format((vente['dateVente'] as Timestamp).toDate())
                      : 'N/A',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(font: lato, fontWeight: pw.FontWeight.bold, fontSize: 12),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
              cellAlignment: pw.Alignment.centerLeft,
              cellStyle: pw.TextStyle(font: lato, fontSize: 12),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Total des ventes : ${ventes.length}",
              style: pw.TextStyle(font: lato, fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _enregistrerRapport(bool isOffline) async {
    setState(() => _isSaving = true);

    try {
      final bytes = await _futurePdf;
      final user = FirebaseAuth.instance.currentUser!;
      final fileName = 'rapport_ventes_${DateTime.now().millisecondsSinceEpoch}.pdf';

      if (!isOffline) {
        final storageRef = FirebaseStorage.instance.ref().child('rapports/$fileName');
        final uploadTask = await storageRef.putData(bytes);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('rapports').add({
          'type': 'vente',
          'date': Timestamp.now(),
          'url': downloadUrl,
          'userId': user.uid,
          'isSynced': true,
        });

        // Hypothetical notification
        // await ServiceNotifications.notifyReportGenerated(
        //   userId: user.uid,
        //   reportType: 'vente',
        //   downloadUrl: downloadUrl,
        // );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rapport enregistré et envoyé avec succès !"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File("${dir.path}/$fileName");
        await file.writeAsBytes(bytes);

        await FirebaseFirestore.instance.collection('pending_rapports').add({
          'type': 'vente',
          'date': Timestamp.now(),
          'filePath': file.path,
          'userId': user.uid,
          'isSynced': false,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Rapport enregistré localement, synchronisation en attente"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print("Erreur lors de l'enregistrement: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
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
          "Rapport des Ventes",
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
        actions: [
          _isSaving
              ? Padding(
                  padding: EdgeInsets.all(basePadding),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.download, size: baseFontSize * 1.5, color: Colors.white),
                  onPressed: () => _enregistrerRapport(context.read<ConnectivityService>().isOffline),
                  tooltip: 'Enregistrer',
                ),
        ],
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
                  child: FutureBuilder<Uint8List>(
                    future: _futurePdf,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Erreur lors de la génération du PDF: ${snapshot.error}",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      return PdfPreview(
                        build: (format) => snapshot.data!,
                        allowPrinting: true,
                        allowSharing: true,
                        padding: EdgeInsets.all(basePadding),
                        pdfFileName: 'rapport_ventes.pdf',
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