import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';

class AjoutMembrePage extends StatefulWidget {
  const AjoutMembrePage({Key? key}) : super(key: key);

  @override
  State<AjoutMembrePage> createState() => _AjoutMembrePageState();
}

class _AjoutMembrePageState extends State<AjoutMembrePage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  File? _image;
  bool isLoading = false;

  final CloudinaryPublic cloudinary = CloudinaryPublic('djlvibqqc', 'AgriTech', cache: false);

  String? nom, sexe, telephone, adresse, culture, statut, photoUrl;
  DateTime? dateNaissance, dateAdhesion;
  double? superficie;

  final List<String> cultures = [
    "Grandes Cultures",
    "Arbres Fruitiers",
    "Légumes",
    "Céréales",
    "Vignes"
  ];

  Future<void> _pickImage() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    if (connectivityService.isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélection d\'image impossible hors ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } catch (e) {
      print('Erreur Cloudinary: $e');
      return null;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Utilisateur non connecté.")),
      );
      setState(() => isLoading = false);
      return;
    }

    final userId = currentUser.uid;

    // Ne pas tenter d'uploader l'image en mode hors ligne
    if (_image != null && !isOffline) {
      photoUrl = await _uploadImageToCloudinary(_image!);
      if (photoUrl == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du téléversement de l’image')),
        );
        return;
      }
    } else {
      photoUrl = null; // Pas d'image en mode hors ligne
    }

    try {
      await FirebaseFirestore.instance.collection('membres').add({
        'nom': nom,
        'sexe': sexe,
        'date_naissance': dateNaissance?.toIso8601String(),
        'telephone': telephone,
        'adresse': adresse,
        'culture': culture,
        'superficie': superficie,
        'statut': statut,
        'photo': photoUrl,
        'date_adhesion': dateAdhesion?.toIso8601String(),
        'userId': userId,
      });

      setState(() => isLoading = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'Membre enregistré localement, synchronisation en attente'
                : 'Membre ajouté avec succès !',
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur d'enregistrement : $e")),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          dateNaissance = picked;
        } else {
          dateAdhesion = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF4CAF50); // vert
    final Color backgroundColor = const Color(0xFFF0EFEA); // beige clair

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Ajout d'un membre"),
      ),
      body: Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
          final bool isOffline = connectivityService.isOffline;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOffline)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        "Hors ligne - Données enregistrées localement, image non téléversée",
                        style: GoogleFonts.lato(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _image != null ? FileImage(_image!) : null,
                        backgroundColor: Colors.grey[300],
                        child: _image == null
                            ? const Icon(Icons.camera_alt, size: 30, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Nom complet", Icons.person, (val) => nom = val),
                  _buildDropdown("Sexe", Icons.wc, ['Homme', 'Femme'], (val) => sexe = val),
                  _buildDatePicker("Date de naissance", Icons.cake, dateNaissance, () => _selectDate(context, true)),
                  _buildTextField("Téléphone", Icons.phone, (val) => telephone = val, isNumber: true),
                  _buildTextField("Adresse", Icons.location_on, (val) => adresse = val),
                  _buildDropdown("Culture pratiquée", Icons.agriculture, cultures, (val) => culture = val),
                  _buildTextField("Superficie (en ha)", Icons.square_foot, (val) => superficie = double.tryParse(val ?? '')),
                  _buildTextField("Statut (membre, adhérent...)", Icons.verified_user, (val) => statut = val),
                  _buildDatePicker("Date d'adhésion", Icons.calendar_today, dateAdhesion, () => _selectDate(context, false)),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Enregistrer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isLoading ? null : _submitForm,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, Function(String?) onSaved, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String label, IconData icon, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Champ requis' : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, IconData icon, DateTime? selectedDate, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            selectedDate != null ? selectedDate.toLocal().toString().split(' ')[0] : 'Sélectionner une date',
            style: TextStyle(color: selectedDate != null ? Colors.black : Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}