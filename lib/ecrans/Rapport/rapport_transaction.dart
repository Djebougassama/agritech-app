import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/../services/connectivity_service.dart';

class RapportTransactionPage extends StatelessWidget {
  const RapportTransactionPage({Key? key}) : super(key: key);

  Future<Uint8List> _generatePdf(List<DocumentSnapshot> data) async {
    final pdf = pw.Document();
    final logoImage = await imageFromAssetBundle('assets/logo_agritech.png');
    final lato = await PdfGoogleFonts.latoRegular();
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, width: 80),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Plateforme AgriTech',
                      style: pw.TextStyle(font: lato, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Rapport des Transactions',
                      style: pw.TextStyle(font: lato, fontSize: 14)),
                  pw.Text("Date : ${dateFormatter.format(DateTime.now())}",
                      style: pw.TextStyle(font: lato, fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(color: PdfColors.grey),
            headerStyle: pw.TextStyle(font: lato, fontWeight: pw.FontWeight.bold, fontSize: 12),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green100),
            headers: ['Date', 'Montant', 'Statut', 'Téléphone', 'Moyen'],
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            cellStyle: pw.TextStyle(font: lato, fontSize: 11),
            data: data.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final date = (d['created_at'] as Timestamp?)?.toDate();
              final formattedDate = date != null ? dateFormatter.format(date) : '';
              return [
                formattedDate,
                '${d['amount'] ?? 0} GNF',
                d['status'] ?? '',
                d['phone'] ?? '',
                d['provider']?.toString().replaceAll('_', ' ').toUpperCase() ?? '',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "Total des transactions : ${data.length}",
            style: pw.TextStyle(font: lato, fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          'Rapport Transactions',
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
                  child: FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('user_id', isEqualTo: userId)
                        .orderBy('created_at', descending: true)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Erreur : ${snapshot.error}',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucune transaction trouvée.',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.green[700],
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!.docs;

                      return PdfPreview(
                        build: (format) => _generatePdf(data),
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        pdfFileName: 'rapport_transactions.pdf',
                        allowPrinting: true,
                        allowSharing: true,
                        padding: EdgeInsets.all(basePadding),
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