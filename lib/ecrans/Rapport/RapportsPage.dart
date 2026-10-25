import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/../services/connectivity_service.dart';
import 'rapport_culture_wrapper.dart';
import 'rapport_stock.dart';
import 'rapport_vente.dart';
import 'rapport_transaction.dart';

class RapportsPage extends StatelessWidget {
  const RapportsPage({Key? key}) : super(key: key);

  void _openReport(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double cardIconSize = baseFontSize * 2.5;
    final double buttonHeight = baseFontSize * 3;

    final cards = [
      {
        'title': 'Rapport des Cultures',
        'color': Colors.green[700],
        'icon': Icons.agriculture,
        'page': RapportCulturePageWrapper(),
      },
      {
        'title': 'Rapport des Stocks',
        'color': Colors.orange[700],
        'icon': Icons.inventory,
        'page': RapportStockPage(),
      },
      {
        'title': 'Rapport des Ventes',
        'color': Colors.blue[700],
        'icon': Icons.shopping_cart,
        'page': RapportVentePage(),
      },
      {
        'title': 'Rapport des Transactions',
        'color': Colors.purple[700],
        'icon': Icons.receipt_long,
        'page': RapportTransactionPage(),
      },
    ];

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          "Rapports",
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
                  child: Padding(
                    padding: EdgeInsets.all(basePadding * 2),
                    child: GridView.builder(
                      itemCount: cards.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: screenWidth < 360 ? 1 : 2,
                        mainAxisSpacing: basePadding * 2,
                        crossAxisSpacing: basePadding * 2,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(basePadding * 1.5),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                    child: IntrinsicHeight(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            card['icon'] as IconData,
                                            size: cardIconSize,
                                            color: card['color'] as Color,
                                          ),
                                          SizedBox(height: basePadding),
                                          Text(
                                            card['title'] as String,
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.lato(
                                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green[900],
                                            ),
                                          ),
                                          SizedBox(height: basePadding),
                                          ElevatedButton(
                                            onPressed: () => _openReport(context, card['page'] as Widget),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: card['color'] as Color,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: basePadding * 2,
                                                vertical: basePadding * 0.8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              minimumSize: Size(double.infinity, buttonHeight),
                                            ),
                                            child: Text(
                                              "Voir PDF",
                                              style: GoogleFonts.lato(
                                                fontSize: baseFontSize * 0.8 * textScaleFactor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
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
