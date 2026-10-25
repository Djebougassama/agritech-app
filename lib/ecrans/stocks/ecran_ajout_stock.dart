import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/notification_service.dart';

class AjouterModifierStockPage extends StatefulWidget {
  final String? stockId;
  final Map<String, dynamic>? stockData;

  AjouterModifierStockPage({this.stockId, this.stockData});

  @override
  _AjouterModifierStockPageState createState() => _AjouterModifierStockPageState();
}

class _AjouterModifierStockPageState extends State<AjouterModifierStockPage> {
  final _formKey = GlobalKey<FormState>();
  final _produitController = TextEditingController();
  final _quantiteController = TextEditingController();
  DateTime? _dateAjout;

  @override
  void initState() {
    super.initState();
    if (widget.stockData != null) {
      _produitController.text = widget.stockData!['produit'] ?? widget.stockData!['Produit'] ?? '';
      _quantiteController.text = widget.stockData!['quantite'].toString();
      _dateAjout = (widget.stockData!['dateAjout'] as Timestamp?)?.toDate() ?? DateTime.now();
    } else {
      _dateAjout = DateTime.now();
    }
  }

  Future<void> _saveStock(bool isOffline) async {
    if (!_formKey.currentState!.validate() || _dateAjout == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs et sélectionner une date"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("Utilisateur non connecté");
      }

      final quantite = int.parse(_quantiteController.text);
      final stockData = {
        'Produit': _produitController.text.trim().toLowerCase(),
        'quantite': quantite,
        'dateAjout': Timestamp.fromDate(_dateAjout!),
        'userId': user.uid,
        'isSynced': !isOffline,
      };

      if (widget.stockId == null) {
        await FirebaseFirestore.instance.collection('stocks').add(stockData);
      } else {
        await FirebaseFirestore.instance.collection('stocks').doc(widget.stockId).update(stockData);
      }

      if (!isOffline) {
        await ServiceNotifications.notifierStockFaible(
          userId: user.uid,
          nomProduit: _produitController.text,
          quantite: quantite,
        );
      } else {
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'stock_faible',
          'userId': user.uid,
          'nomProduit': _produitController.text,
          'quantite': quantite,
          'timestamp': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Stock enregistré localement, synchronisation en attente"
                : widget.stockId == null
                    ? "Stock ajouté avec succès"
                    : "Stock modifié avec succès",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Erreur lors de l'enregistrement du stock: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: Text(
          widget.stockId == null ? "Ajouter un stock" : "Modifier un stock",
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
      ),
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return SingleChildScrollView(
              padding: EdgeInsets.all(basePadding),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (isOffline)
                      Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: Text(
                          'Hors ligne - Données enregistrées localement',
                          style: GoogleFonts.lato(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                          ),
                        ),
                      ),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: TextFormField(
                          controller: _produitController,
                          decoration: InputDecoration(
                            labelText: "Produit",
                            prefixIcon: Icon(Icons.inventory, color: Colors.green, size: baseFontSize * 1.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.green[50],
                            labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          validator: (value) =>
                              value == null || value.isEmpty ? "Veuillez entrer un produit" : null,
                        ),
                      ),
                    ),
                    SizedBox(height: basePadding * 2),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: TextFormField(
                          controller: _quantiteController,
                          decoration: InputDecoration(
                            labelText: "Quantité",
                            prefixIcon: Icon(Icons.format_list_numbered, color: Colors.green, size: baseFontSize * 1.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.green[50],
                            labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Veuillez entrer une quantité";
                            if (int.tryParse(value) == null || int.parse(value) <= 0) return "Quantité invalide";
                            return null;
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: basePadding * 2),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(basePadding),
                        title: Text(
                          "Date d'ajout : ${_dateAjout != null ? _formatDate(_dateAjout!) : "Non définie"}",
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                        ),
                        trailing: Icon(Icons.calendar_today, color: Colors.green[700], size: baseFontSize * 1.2),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _dateAjout ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _dateAjout = date);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: basePadding * 3),
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _saveStock(isOffline),
                            child: Text(
                              widget.stockId == null ? "Ajouter" : "Modifier",
                              style: GoogleFonts.lato(
                                fontSize: baseFontSize * 0.8 * textScaleFactor,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: EdgeInsets.symmetric(
                                horizontal: basePadding * 3,
                                vertical: baseFontSize * 0.8,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              minimumSize: Size(double.infinity, baseFontSize * 3),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  void dispose() {
    _produitController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }
}