import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/connectivity_service.dart';
import 'TransactionsPage.dart';
import 'package:intl/intl.dart';

class VenteDetailPage extends StatefulWidget {
  final Map<String, dynamic> vente;

  const VenteDetailPage({Key? key, required this.vente}) : super(key: key);

  @override
  _VenteDetailPageState createState() => _VenteDetailPageState();
}

class _VenteDetailPageState extends State<VenteDetailPage> {
  int selectedQuantity = 1;
  String? currentUserId;
  bool isOwner = false;
  int nouvelleQuantite = 0;
  TextEditingController _produitController = TextEditingController();
  TextEditingController _prixController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _produitController.text = widget.vente['produit'] ?? '';
    _prixController.text = (widget.vente['prixUnitaire'] as num?)?.toString() ?? '';
    _descriptionController.text = widget.vente['description'] ?? '';
  }

  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
      isOwner = currentUserId == widget.vente['userId'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double imageHeight = screenHeight * 0.3;

    double prixUnitaire = (widget.vente['prixUnitaire'] as num?)?.toDouble() ?? 0.0;
    int quantiteDisponible = widget.vente['quantite'] ?? 0;
    double totalPrice = selectedQuantity * prixUnitaire;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: widget.vente['imageUrl'] != null && widget.vente['imageUrl'].isNotEmpty
                        ? Image.network(
                            widget.vente['imageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: baseFontSize * 3,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image,
                              size: baseFontSize * 3,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isEditing) ...[
                          Text(
                            isOffline
                                ? "${widget.vente['produit'] ?? 'Produit inconnu'} (local)"
                                : widget.vente['produit'] ?? "Produit inconnu",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 1.2 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: basePadding),
                          _buildInfoRow(
                            Icons.monetization_on,
                            "Prix",
                            isOffline
                                ? "$prixUnitaire GNF/${widget.vente['unite'] ?? 'kg'} (local)"
                                : "$prixUnitaire GNF/${widget.vente['unite'] ?? 'kg'}",
                            baseFontSize,
                            textScaleFactor,
                          ),
                          _buildInfoRow(
                            Icons.scale,
                            "Quantité disponible",
                            isOffline
                                ? "$quantiteDisponible ${widget.vente['unite'] ?? 'kg'} (local)"
                                : "$quantiteDisponible ${widget.vente['unite'] ?? 'kg'}",
                            baseFontSize,
                            textScaleFactor,
                          ),
                          SizedBox(height: basePadding * 1.5),
                          Text(
                            "Description",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: basePadding * 0.5),
                          Text(
                            isOffline
                                ? "${widget.vente['description'] ?? 'Aucune description'} (local)"
                                : widget.vente['description'] ?? 'Aucune description',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.8 * textScaleFactor,
                              color: Colors.black87,
                            ),
                          ),
                        ] else ...[
                          _buildEditField(
                            "Nom du produit",
                            _produitController,
                            Icons.shopping_basket,
                            null,
                            1,
                            baseFontSize,
                            textScaleFactor,
                          ),
                          SizedBox(height: basePadding),
                          _buildEditField(
                            "Prix unitaire (GNF)",
                            _prixController,
                            Icons.attach_money,
                            TextInputType.number,
                            1,
                            baseFontSize,
                            textScaleFactor,
                          ),
                          SizedBox(height: basePadding),
                          _buildEditField(
                            "Description",
                            _descriptionController,
                            Icons.description,
                            null,
                            3,
                            baseFontSize,
                            textScaleFactor,
                          ),
                          SizedBox(height: basePadding * 1.5),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _saveChanges(isOffline),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: EdgeInsets.symmetric(vertical: baseFontSize * 0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    "ENREGISTRER",
                                    style: GoogleFonts.lato(
                                      fontWeight: FontWeight.bold,
                                      fontSize: baseFontSize * 0.8 * textScaleFactor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: basePadding),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: baseFontSize * 0.8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    side: BorderSide(color: Colors.green),
                                  ),
                                  child: Text(
                                    "ANNULER",
                                    style: GoogleFonts.lato(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: baseFontSize * 0.8 * textScaleFactor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: basePadding * 1.5),
                        if (quantiteDisponible > 0 && !_isEditing) ...[
                          Divider(color: Colors.grey[300]),
                          SizedBox(height: basePadding * 0.5),
                          Text(
                            "Achat",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: basePadding),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "Quantité :",
                                  style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButton<int>(
                                    value: selectedQuantity,
                                    isExpanded: true,
                                    underline: SizedBox(),
                                    items: List.generate(
                                      quantiteDisponible,
                                      (index) => index + 1,
                                    )
                                        .map((value) => DropdownMenuItem(
                                              value: value,
                                              child: Text(
                                                value.toString(),
                                                style: GoogleFonts.lato(
                                                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedQuantity = value ?? 1;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: basePadding),
                          ElevatedButton.icon(
                            onPressed: () => _acheterProduit(isOffline),
                            icon: Icon(Icons.shopping_cart, size: baseFontSize * 1.2),
                            label: Text(
                              "Acheter pour $totalPrice GNF",
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              minimumSize: Size(double.infinity, baseFontSize * 2.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ] else if (isOwner && !_isEditing) ...[
                          Divider(color: Colors.grey[300]),
                          SizedBox(height: basePadding * 0.5),
                          Text(
                            "Réapprovisionnement",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[800],
                            ),
                          ),
                          SizedBox(height: basePadding),
                          TextField(
                            decoration: InputDecoration(
                              labelText: "Quantité à ajouter",
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.add, size: baseFontSize * 1.2),
                              labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                nouvelleQuantite = int.tryParse(value) ?? 0;
                              });
                            },
                          ),
                          SizedBox(height: basePadding),
                          ElevatedButton.icon(
                            onPressed: () => _reapprovisionner(isOffline),
                            icon: Icon(Icons.inventory, size: baseFontSize * 1.2),
                            label: Text(
                              "Réapprovisionner",
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              minimumSize: Size(double.infinity, baseFontSize * 2.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return Text(
              isOffline
                  ? "${widget.vente['produit'] ?? 'Détail du produit'} (local)"
                  : widget.vente['produit'] ?? "Détail du produit",
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 1.1 * textScaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          },
        ),
        actions: [
          if (isOwner && !_isEditing) ...[
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Colors.white,
                size: baseFontSize * 1.5,
              ),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
            Consumer<ConnectivityService>(
              builder: (context, connectivityService, child) {
                return IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: baseFontSize * 1.5,
                  ),
                  onPressed: () => _confirmDelete(connectivityService.isOffline, baseFontSize, textScaleFactor),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, double baseFontSize, double textScaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: baseFontSize * 0.5),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: baseFontSize * 1.2),
          SizedBox(width: baseFontSize * 0.5),
          Text(
            "$label: ",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.8 * textScaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon,
    TextInputType? keyboardType,
    int maxLines,
    double baseFontSize,
    double textScaleFactor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 0.9 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.green[800],
          ),
        ),
        SizedBox(height: baseFontSize * 0.5),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green, size: baseFontSize * 1.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.green),
            ),
            labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
          ),
          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
          keyboardType: keyboardType,
          maxLines: maxLines,
        ),
      ],
    );
  }

  void _acheterProduit(bool isOffline) async {
    int quantiteDisponible = widget.vente['quantite'] ?? 0;
    if (selectedQuantity > quantiteDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quantité insuffisante"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double prixUnitaire = (widget.vente['prixUnitaire'] as num?)!.toDouble();
    double totalAmount = selectedQuantity * prixUnitaire;
    String venteId = widget.vente['id'];
    DocumentReference venteRef = FirebaseFirestore.instance.collection('ventes').doc(venteId);

    try {
      await venteRef.update({'quantite': quantiteDisponible - selectedQuantity});
      setState(() {
        widget.vente['quantite'] -= selectedQuantity;
      });

      String? stockId = widget.vente['stockId'];
      if (stockId != null) {
        DocumentReference stockRef = FirebaseFirestore.instance.collection('stocks').doc(stockId);
        DocumentSnapshot stockDoc = await stockRef.get();
        if (stockDoc.exists) {
          int quantiteStock = (stockDoc['quantite'] ?? 0);
          await stockRef.update({
            'quantite': quantiteStock - selectedQuantity,
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Achat enregistré localement, synchronisation en attente"
                : "Achat effectué avec succès !",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PagePaiement(amount: totalAmount),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'achat: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reapprovisionner(bool isOffline) async {
    if (nouvelleQuantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer une quantité valide"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    int quantiteDisponible = widget.vente['quantite'] ?? 0;
    String venteId = widget.vente['id'];
    DocumentReference venteRef = FirebaseFirestore.instance.collection('ventes').doc(venteId);

    try {
      await venteRef.update({'quantite': quantiteDisponible + nouvelleQuantite});
      setState(() {
        widget.vente['quantite'] += nouvelleQuantite;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Réapprovisionnement enregistré localement, synchronisation en attente"
                : "Stock réapprovisionné avec succès !",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du réapprovisionnement: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveChanges(bool isOffline) async {
    if (_produitController.text.isEmpty || _prixController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? prix = double.tryParse(_prixController.text);
    if (prix == null || prix <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer un prix valide"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String venteId = widget.vente['id'];
      DocumentReference venteRef = FirebaseFirestore.instance.collection('ventes').doc(venteId);

      await venteRef.update({
        'produit': _produitController.text,
        'prixUnitaire': prix,
        'description': _descriptionController.text,
      });

      setState(() {
        widget.vente['produit'] = _produitController.text;
        widget.vente['prixUnitaire'] = prix;
        widget.vente['description'] = _descriptionController.text;
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Modifications enregistrées localement, synchronisation en attente"
                : "Modifications enregistrées avec succès !",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la mise à jour: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(bool isOffline, double baseFontSize, double textScaleFactor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirmer la suppression",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Voulez-vous vraiment supprimer ce produit ? Cette action est irréversible.",
            style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Annuler",
                style: GoogleFonts.lato(
                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteVente(isOffline);
              },
              child: Text(
                "Supprimer",
                style: GoogleFonts.lato(
                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _deleteVente(bool isOffline) async {
    try {
      String venteId = widget.vente['id'];
      await FirebaseFirestore.instance.collection('ventes').doc(venteId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Produit supprimé localement, synchronisation en attente"
                : "Produit supprimé avec succès !",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la suppression: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _produitController.dispose();
    _prixController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}