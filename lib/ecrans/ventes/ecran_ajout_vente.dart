import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/../services/connectivity_service.dart';
import '../../services/notification_service.dart';
import 'package:path_provider/path_provider.dart';

class AjoutVente extends StatefulWidget {
  @override
  _AjoutVenteState createState() => _AjoutVenteState();
}

class _AjoutVenteState extends State<AjoutVente> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _produitController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _prixController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _image;
  final CloudinaryPublic cloudinary = CloudinaryPublic('djlvibqqc', 'AgriTech', cache: false);
  bool _isLoading = false;
  String _unite = 'kg';
  List<Map<String, dynamic>> _stocksDisponibles = [];
  Map<String, dynamic>? _stockSelectionne;

  @override
  void initState() {
    super.initState();
    _chargerStocks();
  }

  Future<void> _chargerStocks() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Utilisateur non connecté"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final bool isOffline = connectivityService.isOffline;

      final snapshot = await FirebaseFirestore.instance
          .collection('stocks')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) {
        print("Aucun stock trouvé pour cet utilisateur");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Aucun stock disponible"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _stocksDisponibles = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final produit = data['Produit'] ?? data['produit'] ?? 'Nom inconnu';
          return {
            'id': doc.id,
            'produit': produit,
            'quantite': data['quantite'] ?? 0,
            'description': data['description'] ?? '',
          };
        }).toList();
      });

      if (isOffline) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stocks chargés localement'),
              backgroundColor: Colors.orange,
            ),
          );
        });
      }
    } catch (e) {
      print("Erreur lors du chargement des stocks: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors du chargement des stocks: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Widget _buildProduitDropdown(bool isOffline, double baseFontSize, double textScaleFactor) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: baseFontSize * 0.5),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: _stockSelectionne,
        decoration: InputDecoration(
          labelText: 'Produit en stock',
          prefixIcon: Icon(Icons.inventory, color: Colors.green, size: baseFontSize * 1.2),
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
        ),
        items: _stocksDisponibles.isEmpty
            ? [
                DropdownMenuItem(
                  child: Text(
                    "Aucun produit disponible",
                    style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                )
              ]
            : _stocksDisponibles.map((stock) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: stock,
                  child: Text(
                    isOffline
                        ? '${stock['produit']} (${stock['quantite']} ${stock['quantite'] == 1 ? 'unité' : _unite.toLowerCase()} disponible${stock['quantite'] == 1 ? '' : 's'}) (local)'
                        : '${stock['produit']} (${stock['quantite']} ${stock['quantite'] == 1 ? 'unité' : _unite.toLowerCase()} disponible${stock['quantite'] == 1 ? '' : 's'})',
                    style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                  ),
                );
              }).toList(),
        onChanged: (selectedStock) {
          setState(() {
            _stockSelectionne = selectedStock;
            if (selectedStock != null) {
              _produitController.text = selectedStock['produit'];
              _descriptionController.text = selectedStock['description'];
              _quantiteController.text = selectedStock['quantite'].toString();
            }
          });
        },
        validator: (value) => value == null ? 'Sélectionnez un produit' : null,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    TextInputType type,
    IconData icon,
    String? Function(String?)? validator,
    double baseFontSize,
    double textScaleFactor, {
    bool readOnly = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: baseFontSize * 0.5),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.green, size: baseFontSize * 1.2),
          filled: true,
          fillColor: Colors.green[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
        ),
        style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
        validator: validator ?? (value) => value!.isEmpty ? "Champ obligatoire" : null,
      ),
    );
  }

  Future<void> _uploadVente(bool isOffline) async {
    if (!_formKey.currentState!.validate()) return;
    if (_stockSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un produit"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quantiteSaisie = int.parse(_quantiteController.text);
    if (quantiteSaisie > _stockSelectionne!['quantite']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quantité supérieure au stock disponible"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      String? imageUrl;
      String? pendingImagePath;

      if (_image != null) {
        if (isOffline) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'pending_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await _image!.copy('${directory.path}/$fileName');
          pendingImagePath = savedImage.path;
        } else {
          CloudinaryResponse response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(_image!.path, resourceType: CloudinaryResourceType.Image),
          );
          imageUrl = response.secureUrl;
        }
      }

      final venteData = {
        'produit': _produitController.text,
        'quantite': quantiteSaisie,
        'prixUnitaire': double.parse(_prixController.text),
        'dateVente': Timestamp.now(),
        'description': _descriptionController.text,
        'unite': _unite,
        'imageUrl': imageUrl,
        'pendingImagePath': pendingImagePath,
        'userId': userId,
        'stockId': _stockSelectionne!['id'],
        'isSynced': !isOffline,
      };

      final venteRef = await FirebaseFirestore.instance.collection('ventes').add(venteData);

      final nouvelleQuantite = _stockSelectionne!['quantite'] - quantiteSaisie;
      await FirebaseFirestore.instance
          .collection('stocks')
          .doc(_stockSelectionne!['id'])
          .update({'quantite': nouvelleQuantite});

      if (!isOffline) {
        await ServiceNotifications.notifierNouvelleVente(
          userId: userId,
          produit: _produitController.text,
          montant: double.parse(_prixController.text),
        );

        if (nouvelleQuantite <= 0) {
          await ServiceNotifications.notifierRuptureStock(
            userId: userId,
            produit: _produitController.text,
          );
        }
      } else {
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'nouvelle_vente',
          'userId': userId,
          'produit': _produitController.text,
          'montant': double.parse(_prixController.text),
          'timestamp': Timestamp.now(),
        });

        if (nouvelleQuantite <= 0) {
          await FirebaseFirestore.instance.collection('pending_notifications').add({
            'type': 'rupture_stock',
            'userId': userId,
            'produit': _produitController.text,
            'timestamp': Timestamp.now(),
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline ? "Vente enregistrée localement, synchronisation en attente" : "Vente ajoutée avec succès !",
          ),
          backgroundColor: isOffline ? Colors.blue : Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Erreur: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'enregistrement: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double imageSize = screenWidth * 0.4;

    return Scaffold(
      backgroundColor: Colors.green[100],
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
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                          ),
                        ),
                      ),
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: _image != null
                                  ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                                  : null,
                              color: Colors.green[200],
                            ),
                            child: _image == null
                                ? Center(
                                    child: Icon(
                                      Icons.image,
                                      size: baseFontSize * 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: Colors.green,
                              child: Icon(
                                Icons.add_a_photo,
                                color: Colors.white,
                                size: baseFontSize * 1.2,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: basePadding),
                    _buildProduitDropdown(isOffline, baseFontSize, textScaleFactor),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            "Quantité",
                            _quantiteController,
                            TextInputType.number,
                            Icons.format_list_numbered,
                            (value) {
                              if (value!.isEmpty) return "Champ obligatoire";
                              if (int.tryParse(value) == null || int.parse(value) <= 0) return "Quantité invalide";
                              return null;
                            },
                            baseFontSize,
                            textScaleFactor,
                            readOnly: true,
                          ),
                        ),
                        SizedBox(width: basePadding * 0.5),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: basePadding * 0.5, vertical: basePadding * 0.2),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green),
                          ),
                          child: DropdownButton<String>(
                            value: _unite,
                            icon: Icon(Icons.arrow_drop_down, size: baseFontSize * 1.2),
                            underline: SizedBox(),
                            style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            onChanged: (String? newValue) {
                              setState(() {
                                _unite = newValue!;
                              });
                            },
                            items: <String>['kg', 'sac', 'caisse', 'unité']
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    _buildTextField(
                      "Prix Unitaire",
                      _prixController,
                      TextInputType.number,
                      Icons.attach_money,
                      (value) {
                        if (value!.isEmpty) return "Champ obligatoire";
                        if (double.tryParse(value) == null || double.parse(value)! <= 0) return "Prix invalide";
                        return null;
                      },
                      baseFontSize,
                      textScaleFactor,
                    ),
                    _buildTextField(
                      "Description",
                      _descriptionController,
                      TextInputType.text,
                      Icons.description,
                      null,
                      baseFontSize,
                      textScaleFactor,
                    ),
                    SizedBox(height: basePadding * 1.5),
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.green)
                        : ElevatedButton.icon(
                            onPressed: () => _uploadVente(isOffline),
                            icon: Icon(Icons.add_shopping_cart, size: baseFontSize * 1.2),
                            label: Text(
                              "Ajouter la vente",
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: basePadding * 2, vertical: baseFontSize * 0.8),
                              backgroundColor: Colors.green[700],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              color: Colors.white,
              size: baseFontSize * 1.5,
            ),
            SizedBox(width: basePadding),
            Text(
              "Ajouter une Vente",
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 1.1 * textScaleFactor,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
    );
  }

  @override
  void dispose() {
    _produitController.dispose();
    _quantiteController.dispose();
    _prixController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}