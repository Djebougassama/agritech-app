import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';
import 'package:agri_tech_app/ecrans/Notifications/notifications_page.dart';

class AjouterModifierCulturePage extends StatefulWidget {
  final String? cultureId;
  final Map<String, dynamic>? cultureData;
  

  AjouterModifierCulturePage({this.cultureId, this.cultureData});

  @override
  _AjouterModifierCulturePageState createState() => _AjouterModifierCulturePageState();
}

class _AjouterModifierCulturePageState extends State<AjouterModifierCulturePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  String? selectedType;
  DateTime? _datePlantation;
  DateTime? _dateRecolte;
  final _rendementController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.cultureData != null) {
      _nomController.text = widget.cultureData!['nom'];
      selectedType = widget.cultureData!['type'];
      _datePlantation = (widget.cultureData!['datePlantation'] as Timestamp).toDate();
      _dateRecolte = (widget.cultureData!['dateRecolte'] as Timestamp).toDate();
      _rendementController.text = widget.cultureData!['rendement'].toString();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Non définie";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _submitForm() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    if (_formKey.currentState!.validate()) {
      if (_datePlantation == null || _dateRecolte == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veuillez sélectionner les dates'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final user = _auth.currentUser;
        if (user == null) throw Exception('Utilisateur non connecté');

        final cultureData = {
          'nom': _nomController.text,
          'type': selectedType,
          'datePlantation': Timestamp.fromDate(_datePlantation!),
          'dateRecolte': Timestamp.fromDate(_dateRecolte!),
          'rendement': double.parse(_rendementController.text),
          'userId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          if (widget.cultureId == null) 'createdAt': FieldValue.serverTimestamp(),
        };

        if (widget.cultureId == null) {
          await FirebaseFirestore.instance.collection('cultures').add(cultureData);

          await NotificationsPage.ajouterNotificationAutomatique(
  userId: user.uid,
  titre: isOffline
      ? '🌱 Nouvelle culture : ${_nomController.text} (local)'
      : '🌱 Nouvelle culture : ${_nomController.text}',
  message: isOffline
      ? 'Pensez à arroser votre culture chaque jour à 7h. (local)'
      : 'Pensez à arroser votre culture chaque jour à 7h.',
  type: 'culture',
  isOffline: isOffline,
);


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOffline
                    ? 'Culture enregistrée localement, synchronisation en attente'
                    : 'Culture enregistrée avec succès',
              ),
              backgroundColor: isOffline ? Colors.orange : Colors.green,
            ),
          );
        } else {
          await FirebaseFirestore.instance
              .collection('cultures')
              .doc(widget.cultureId)
              .update(cultureData);

          await NotificationsPage.ajouterNotificationAutomatique(
  userId: user.uid,
  titre: isOffline
      ? '🔄 Mise à jour : ${_nomController.text} (local)'
      : '🔄 Mise à jour : ${_nomController.text}',
  message: isOffline
      ? 'Les informations de la culture ont été modifiées localement.'
      : 'Les informations de la culture ont été modifiées avec succès.',
  type: 'culture',
  isOffline: isOffline,
);


          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isOffline
                    ? 'Culture modifiée localement, synchronisation en attente'
                    : 'Culture modifiée avec succès',
              ),
              backgroundColor: isOffline ? Colors.orange : Colors.green,
            ),
          );
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPlantation) async {
    final double baseFontSize = MediaQuery.of(context).size.width < 360 ? 14 : 16;
    final picked = await showDatePicker(
      context: context,
      initialDate: isPlantation ? _datePlantation ?? DateTime.now() : _dateRecolte ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            textTheme: TextTheme(
              bodyLarge: GoogleFonts.lato(fontSize: baseFontSize * 0.9),
              bodyMedium: GoogleFonts.lato(fontSize: baseFontSize * 0.8),
            ),
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isPlantation) {
          _datePlantation = picked;
        } else {
          _dateRecolte = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    if (isOffline)
                      Padding(
                        padding: EdgeInsets.only(bottom: basePadding),
                        child: Text(
                          'Hors ligne - Les données seront synchronisées plus tard',
                          style: GoogleFonts.lato(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                          ),
                        ),
                      ),
                    _buildCard(
                      child: TextFormField(
                        controller: _nomController,
                        decoration: InputDecoration(
                          labelText: "Nom de la culture",
                          border: InputBorder.none,
                          labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                        ),
                        style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                        validator: (value) => value!.isEmpty ? "Veuillez entrer un nom" : null,
                      ),
                    ),
                    SizedBox(height: basePadding),
                    _buildCard(
                      child: DropdownButtonFormField<String>(
                        value: selectedType,
                        decoration: InputDecoration(
                          labelText: "Type de culture",
                          border: InputBorder.none,
                          labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                        ),
                        items: [
                          "Céréales",
                          "Légumineuses",
                          "Légumes",
                          "Fruits",
                          "Tubercules",
                          "Oléagineux",
                          "Plantes fourragères",
                          "Plantes médicinales",
                          "Cultures industrielles",
                          "Cultures maraîchères",
                        ].map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type, style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor)),
                            )).toList(),
                        onChanged: (newValue) => setState(() => selectedType = newValue),
                        validator: (value) => value == null ? "Veuillez sélectionner un type" : null,
                      ),
                    ),
                    SizedBox(height: basePadding),
                    _buildCard(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(
                              "Date de plantation",
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                            ),
                            subtitle: Text(
                              _formatDate(_datePlantation),
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            trailing: Icon(
                              Icons.calendar_today,
                              color: Colors.green.shade700,
                              size: baseFontSize * 1.2,
                            ),
                            onTap: () => _selectDate(context, true),
                          ),
                          Divider(),
                          ListTile(
                            title: Text(
                              "Date de récolte",
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                            ),
                            subtitle: Text(
                              _formatDate(_dateRecolte),
                              style: GoogleFonts.lato(fontSize: baseFontSize * 0.8 * textScaleFactor),
                            ),
                            trailing: Icon(
                              Icons.calendar_today,
                              color: Colors.green.shade700,
                              size: baseFontSize * 1.2,
                            ),
                            onTap: () => _selectDate(context, false),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: basePadding),
                    _buildCard(
                      child: TextFormField(
                        controller: _rendementController,
                        decoration: InputDecoration(
                          labelText: "Rendement (en tonnes)",
                          border: InputBorder.none,
                          labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                        ),
                        style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value!.isEmpty) return "Veuillez entrer un rendement";
                          if (double.tryParse(value) == null) return "Valeur invalide";
                          return null;
                        },
                      ),
                    ),
                    SizedBox(height: basePadding * 1.5),
                    SizedBox(
                      width: screenWidth * 0.9,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: Text(
                          widget.cultureId == null ? "AJOUTER" : "MODIFIER",
                          style: GoogleFonts.lato(
                            fontSize: baseFontSize * 0.9 * textScaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(vertical: baseFontSize * 0.8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.agriculture,
              color: Colors.white,
              size: baseFontSize * 1.5,
            ),
            SizedBox(width: basePadding * 0.5),
            Text(
              widget.cultureId == null ? "Ajouter une culture" : "Modifier une culture",
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 1.1 * textScaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        toolbarHeight: baseFontSize * 4,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(screenWidth * 0.02),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _rendementController.dispose();
    super.dispose();
  }
}