import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/../services/connectivity_service.dart';

class AjoutRecoltesPage extends StatefulWidget {
  @override
  _AjoutRecoltesPageState createState() => _AjoutRecoltesPageState();
}

class _AjoutRecoltesPageState extends State<AjoutRecoltesPage> {
  String? selectedCulture;
  double? quantite;
  DateTime? dateRecolte;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  List<QueryDocumentSnapshot> culturesDocs = [];

  @override
  void dispose() {
    _quantiteController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = dateRecolte ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.green[900]!,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        dateRecolte = picked;
        _dateController.text = "${picked.day.toString().padLeft(2, '0')}/"
            "${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  void _onCultureChanged(String? cultureName) {
    if (cultureName == null) return;
    setState(() {
      selectedCulture = cultureName;
      final doc = culturesDocs.firstWhere((doc) => doc['nom'] == cultureName);

      quantite = (doc['rendement'] is int)
          ? (doc['rendement'] as int).toDouble()
          : (doc['rendement'] as double);
      dateRecolte = (doc['dateRecolte'] as Timestamp).toDate();

      _quantiteController.text = quantite.toString();
      _dateController.text = "${dateRecolte!.day.toString().padLeft(2, '0')}/"
          "${dateRecolte!.month.toString().padLeft(2, '0')}/${dateRecolte!.year}";
    });
  }

  Future<void> _enregistrerRecolte(bool isOffline) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez vérifier les informations saisies"),
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

      final cultureName = selectedCulture?.trim();
      final quantite = int.tryParse(_quantiteController.text.trim()) ?? 0;

      if (cultureName == null || quantite <= 0 || dateRecolte == null) {
        throw Exception("Données invalides");
      }

      final recolteData = {
        'nomCulture': selectedCulture,
        'quantite': quantite,
        'unite': 'kg',
        'dateRecolte': Timestamp.fromDate(dateRecolte!),
        'userId': user.uid,
        'isSynced': !isOffline,
      };

      final recolteRef = await FirebaseFirestore.instance.collection('recoltes').add(recolteData);

      final stockQuery = await FirebaseFirestore.instance
          .collection('stocks')
          .where('Produit', isEqualTo: cultureName)
          .where('userId', isEqualTo: user.uid)
          .get();

      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final currentStock = (stockDoc['quantite'] ?? 0) as int;
        await FirebaseFirestore.instance.collection('stocks').doc(stockDoc.id).update({
          'quantite': currentStock + quantite,
          'isSynced': !isOffline,
        });
      } else {
        await FirebaseFirestore.instance.collection('stocks').add({
          'Produit': cultureName,
          'quantite': quantite,
          'dateAjout': Timestamp.now(),
          'userId': user.uid,
          'isSynced': !isOffline,
        });
      }

      if (!isOffline) {
        // Hypothetical notification
        // await ServiceNotifications.notifyRecolteAdded(
        //   userId: user.uid,
        //   nomCulture: cultureName,
        //   quantite: quantite,
        //   unite: 'kg',
        // );
      } else {
        await FirebaseFirestore.instance.collection('pending_notifications').add({
          'type': 'recolte_added',
          'userId': user.uid,
          'nomCulture': cultureName,
          'quantite': quantite,
          'unite': 'kg',
          'timestamp': Timestamp.now(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? "Récolte enregistrée localement, synchronisation en attente"
                : "Récolte enregistrée avec succès",
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Erreur lors de l'enregistrement: $e");
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

  InputDecoration _inputDecoration(String label, IconData icon, double baseFontSize, double textScaleFactor) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.lato(
        color: Colors.green[900],
        fontWeight: FontWeight.w600,
        fontSize: baseFontSize * 0.8 * textScaleFactor,
      ),
      prefixIcon: Icon(icon, color: Colors.green[700], size: baseFontSize * 1.2),
      filled: true,
      fillColor: Colors.green[50],
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.green[700]!, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(vertical: baseFontSize * 0.8, horizontal: baseFontSize),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text(
          'Ajouter une récolte',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 5,
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
            return Padding(
              padding: EdgeInsets.all(basePadding * 2),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('cultures')
                    .where('userId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur en chargeant les cultures : ${snapshot.error}',
                        style: GoogleFonts.lato(
                          color: Colors.redAccent,
                          fontSize: baseFontSize * 0.9 * textScaleFactor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator(color: Colors.green[700]));
                  }

                  culturesDocs = snapshot.data!.docs;
                  final culturesList = culturesDocs.map((doc) => doc['nom'] as String).toList();

                  return SingleChildScrollView(
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
                          DropdownButtonFormField<String>(
                            decoration: _inputDecoration('Culture', Icons.agriculture_rounded, baseFontSize, textScaleFactor),
                            value: selectedCulture,
                            items: culturesList.map((cultureName) {
                              return DropdownMenuItem<String>(
                                value: cultureName,
                                child: Text(
                                  cultureName + (isOffline ? ' (local)' : ''),
                                  style: GoogleFonts.lato(
                                    color: Colors.green[900],
                                    fontSize: baseFontSize * 0.8 * textScaleFactor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onCultureChanged,
                            validator: (value) => value == null ? 'Veuillez choisir une culture' : null,
                            dropdownColor: Colors.green[50],
                          ),
                          SizedBox(height: basePadding * 2),
                          TextFormField(
                            controller: _quantiteController,
                            decoration: _inputDecoration('Quantité (rendement)', Icons.format_list_numbered_rounded, baseFontSize, textScaleFactor),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Veuillez entrer une quantité';
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed <= 0) return 'Veuillez entrer un nombre valide';
                              return null;
                            },
                            style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          SizedBox(height: basePadding * 2),
                          TextFormField(
                            controller: _dateController,
                            decoration: _inputDecoration('Date de récolte', Icons.calendar_today_rounded, baseFontSize, textScaleFactor).copyWith(
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.clear, color: Colors.redAccent, size: baseFontSize * 1.2),
                                    onPressed: () {
                                      setState(() {
                                        dateRecolte = null;
                                        _dateController.clear();
                                      });
                                    },
                                  ),
                                  Icon(Icons.calendar_today_rounded, color: Colors.green[700], size: baseFontSize * 1.2),
                                  SizedBox(width: basePadding),
                                ],
                              ),
                            ),
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            validator: (value) => value == null || value.isEmpty ? 'Veuillez choisir une date' : null,
                            style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                          ),
                          SizedBox(height: basePadding * 3),
                          _isLoading
                              ? CircularProgressIndicator(color: Colors.green[700])
                              : ElevatedButton(
                                  onPressed: () => _enregistrerRecolte(isOffline),
                                  child: Text(
                                    'Enregistrer',
                                    style: GoogleFonts.lato(
                                      fontSize: baseFontSize * 0.8 * textScaleFactor,
                                      fontWeight: FontWeight.w700,
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
            );
          },
        ),
      ),
    );
  }
}