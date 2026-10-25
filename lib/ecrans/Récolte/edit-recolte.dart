import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';

class EditRecoltePage extends StatefulWidget {
  const EditRecoltePage({super.key});

  @override
  State<EditRecoltePage> createState() => _EditRecoltePageState();
}

class _EditRecoltePageState extends State<EditRecoltePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomProduitController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  DateTime? _selectedDate;
  String? _photoUrl;
  String? _membreNom;
  String? _recolteId;
  String? _userId;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final data = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (data != null) {
      _recolteId = data['id'];
      _userId = data['userId'];
      _nomProduitController.text = data['nomProduit'] ?? '';
      _quantiteController.text = data['quantite']?.toString() ?? '';
      _selectedDate = (data['dateRecolte'] is Timestamp)
          ? (data['dateRecolte'] as Timestamp).toDate()
          : DateTime.tryParse(data['dateRecolte'] ?? '') ?? DateTime.now();
      _photoUrl = data['photoUrl'];
      _membreNom = data['membreNom'];
    }
  }

  Future<void> _updateRecolte(bool isOffline) async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _recolteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs requis"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantite = int.tryParse(_quantiteController.text) ?? 0;
      if (quantite <= 0 || _nomProduitController.text.trim().isEmpty) {
        throw Exception("Données invalides");
      }

      final updateData = {
        'nomProduit': _nomProduitController.text.trim(),
        'quantite': quantite,
        'dateRecolte': Timestamp.fromDate(_selectedDate!),
        'photoUrl': _photoUrl,
        'membreNom': _membreNom,
        'userId': _userId,
        'isSynced': !isOffline,
      };

      await FirebaseFirestore.instance.collection('recoltes').doc(_recolteId).update(updateData);

      if (!isOffline && _userId != null) {
        // Hypothetical notification
        // await ServiceNotifications.notifyRecolteUpdate(
        //   userId: _userId!,
        //   nomCulture: _nomProduitController.text.trim(),
        //   quantite: quantite.toDouble(),
        //   unite: 'kg', // Adjust if unit is stored elsewhere
        // );
      } else if (isOffline && _userId != null) {
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'recolte_update',
          'userId': _userId,
          'nomCulture': _nomProduitController.text.trim(),
          'quantite': quantite,
          'unite': 'kg',
          'timestamp': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Modification enregistrée localement, synchronisation en attente"
                : "Récolte modifiée avec succès",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Erreur lors de la modification: $e");
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        title: Text(
          'Modifier la récolte',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
                          controller: _nomProduitController,
                          decoration: InputDecoration(
                            labelText: 'Nom du produit',
                            prefixIcon: Icon(Icons.agriculture, color: Colors.green, size: baseFontSize * 1.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.green[50],
                            labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          validator: (value) => value!.isEmpty ? 'Champ requis' : null,
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
                            labelText: 'Quantité',
                            prefixIcon: Icon(Icons.format_list_numbered, color: Colors.green, size: baseFontSize * 1.2),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.green[50],
                            labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value!.isEmpty) return 'Champ requis';
                            if (int.tryParse(value) == null || int.parse(value) <= 0) return 'Quantité invalide';
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
                          _selectedDate != null
                              ? 'Date de récolte : ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}'
                              : 'Sélectionner une date',
                          style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                        ),
                        trailing: Icon(
                          Icons.calendar_today,
                          color: Colors.green[700],
                          size: baseFontSize * 1.2,
                        ),
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    SizedBox(height: basePadding * 3),
                    _isLoading
                        ? CircularProgressIndicator(color: Colors.green)
                        : ElevatedButton(
                            onPressed: () => _updateRecolte(isOffline),
                            child: Text(
                              'Enregistrer les modifications',
                              style: GoogleFonts.lato(
                                fontSize: baseFontSize * 0.8 * textScaleFactor,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
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

  @override
  void dispose() {
    _nomProduitController.dispose();
    _quantiteController.dispose();
    super.dispose();
  }
}