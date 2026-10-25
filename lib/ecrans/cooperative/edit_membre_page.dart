import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agri_tech_app/services/connectivity_service.dart';
import 'dart:io';

class EditMembrePage extends StatefulWidget {
  final String membreId;
  final Map<String, dynamic> membreData;

  const EditMembrePage({
    Key? key,
    required this.membreId,
    required this.membreData,
  }) : super(key: key);

  @override
  State<EditMembrePage> createState() => _EditMembrePageState();
}

class _EditMembrePageState extends State<EditMembrePage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  File? _image;
  bool isLoading = false;



  final CloudinaryPublic cloudinary = CloudinaryPublic('djlvibqqc', 'AgriTech', cache: false);

  late String? nom, sexe, telephone, adresse, culture, statut, photoUrl;
  DateTime? dateNaissance, dateAdhesion;
  double? superficie;

  final List<String> cultures = [
    "Grandes Cultures",
    "Arbres Fruitiers",
    "Légumes",
    "Céréales",
    "Vignes"
  ];

  @override
  void initState() {
    super.initState();
    nom = widget.membreData['nom'];
    sexe = widget.membreData['sexe'];
    telephone = widget.membreData['telephone'];
    adresse = widget.membreData['adresse'];
    culture = widget.membreData['culture'];
    statut = widget.membreData['statut'];
    photoUrl = widget.membreData['photo'];
    superficie = (widget.membreData['superficie'] as num?)?.toDouble();

    final dn = widget.membreData['date_naissance'];
    final da = widget.membreData['date_adhesion'];
    if (dn != null) dateNaissance = DateTime.tryParse(dn);
    if (da != null) dateAdhesion = DateTime.tryParse(da);
  }

  Future<void> _pickImage() async {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    if (isOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de téléverser une image hors ligne'),
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
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = connectivityService.isOffline;

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (isOffline && _image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de téléverser une image hors ligne'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    if (_image != null) {
      photoUrl = await _uploadImageToCloudinary(_image!);
      if (photoUrl == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échec du téléversement de l’image')),
        );
        return;
      }
    }

    try {
      await FirebaseFirestore.instance.collection('membres').doc(widget.membreId).update({
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOffline
                ? 'Modifications enregistrées localement, synchronisation en attente'
                : 'Membre mis à jour avec succès !',
          ),
          backgroundColor: isOffline ? Colors.orange : Colors.green,
        ),
      );
      setState(() => isLoading = false);
      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de la mise à jour : $e')),
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
    final Color primaryColor = const Color(0xFF4CAF50);
    final Color backgroundColor = const Color(0xFFF0EFEA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("Modifier le membre"),
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
                        "Hors ligne - Modifications enregistrées localement",
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _image != null
                                ? FileImage(_image!)
                                : (photoUrl != null ? NetworkImage(photoUrl!) : null) as ImageProvider?,
                            backgroundColor: Colors.grey[300],
                            child: (_image == null && photoUrl == null)
                                ? const Icon(Icons.camera_alt, size: 30, color: Colors.white)
                                : null,
                          ),
                          if (isOffline)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                color: Colors.black54,
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  'Image non modifiable hors ligne',
                                  style: GoogleFonts.lato(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField("Nom complet", Icons.person, (val) => nom = val, initialValue: nom, isOffline: isOffline),
                  _buildDropdown("Sexe", Icons.wc, ['Homme', 'Femme'], (val) => sexe = val, value: sexe, isOffline: isOffline),
                  _buildDatePicker("Date de naissance", Icons.cake, dateNaissance, () => _selectDate(context, true), isOffline: isOffline),
                  _buildTextField("Téléphone", Icons.phone, (val) => telephone = val, isNumber: true, initialValue: telephone, isOffline: isOffline),
                  _buildTextField("Adresse", Icons.location_on, (val) => adresse = val, initialValue: adresse, isOffline: isOffline),
                  _buildDropdown("Culture pratiquée", Icons.agriculture, cultures, (val) => culture = val, value: culture, isOffline: isOffline),
                  _buildTextField("Superficie (en ha)", Icons.square_foot, (val) => superficie = double.tryParse(val ?? ''), initialValue: superficie?.toString(), isOffline: isOffline),
                  _buildTextField("Statut (membre, adhérent...)", Icons.verified_user, (val) => statut = val, initialValue: statut, isOffline: isOffline),
                  _buildDatePicker("Date d'adhésion", Icons.calendar_today, dateAdhesion, () => _selectDate(context, false), isOffline: isOffline),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.save),
                      label: const Text("Mettre à jour"),
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

  Widget _buildTextField(String label, IconData icon, Function(String?) onSaved, {bool isNumber = false, String? initialValue, required bool isOffline}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: isOffline ? '$label (local)' : label,
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

  Widget _buildDropdown(String label, IconData icon, List<String> options, Function(String?) onChanged, {String? value, required bool isOffline}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: isOffline ? '$label (local)' : label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
      ),
    );
  }

  Widget _buildDatePicker(String label, IconData icon, DateTime? selectedDate, VoidCallback onTap, {required bool isOffline}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: isOffline ? '$label (local)' : label,
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