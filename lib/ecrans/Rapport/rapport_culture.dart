import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../modeles/culture.dart';
import '../../services/connectivity_service.dart';

class RapportCulturePage extends StatelessWidget {
  final List<Culture> cultures;

  const RapportCulturePage({required this.cultures});

  Future<Uint8List> _generatePdf(PdfPageFormat format, List<Culture> data) async {
    final pdf = pw.Document();
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final logoImage = await imageFromAssetBundle('assets/logo_agritech.png');

    final lato = await PdfGoogleFonts.latoRegular();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Image(logoImage, width: 80),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Plateforme AgriTech",
                      style: pw.TextStyle(font: lato, fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Rapport des Cultures",
                      style: pw.TextStyle(font: lato, fontSize: 14)),
                  pw.Text("Date : ${dateFormatter.format(DateTime.now())}",
                      style: pw.TextStyle(font: lato, fontSize: 10)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ['Nom', 'Type', 'Plantation', 'Récolte', 'Rendement (tonnes)'],
            data: data.map((culture) {
              return [
                culture.nom ?? '',
                culture.type ?? '',
                culture.datePlantation != null ? dateFormatter.format(culture.datePlantation!) : '-',
                culture.dateRecolte != null ? dateFormatter.format(culture.dateRecolte!) : '-',
                '${culture.rendement ?? 0}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(font: lato, fontWeight: pw.FontWeight.bold, fontSize: 12),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green200),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
              4: const pw.FlexColumnWidth(1.5),
            },
            cellStyle: pw.TextStyle(font: lato, fontSize: 11),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey, width: 0.5)),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            "Total des cultures : ${data.length}",
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

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          "Rapport des Cultures",
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
                      'Hors ligne - Affichage local',
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                  ),
                Expanded(
                  child: PdfPreview(
                    build: (format) => _generatePdf(format, cultures),
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    allowSharing: true,
                    allowPrinting: true,
                    useActions: true,
                    padding: EdgeInsets.all(basePadding),
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