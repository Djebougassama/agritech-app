import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/connectivity_service.dart';

class UtilisateurProfil extends StatefulWidget {
  const UtilisateurProfil({super.key});

  @override
  State<UtilisateurProfil> createState() => _UtilisateurProfilState();
}

class _UtilisateurProfilState extends State<UtilisateurProfil> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryPublic cloudinary = CloudinaryPublic('djlvibqqc', 'AgriTech', cache: false);

  late User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false;

  final _formKey = GlobalKey<FormState>();
  String? _nom, _ville, _telephone, _photoUrl;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    setState(() => _isLoading = true);
    _user = _auth.currentUser;
    if (_user != null) {
      final uid = _user!.uid;
      final utilisateurDoc = await _firestore.collection('utilisateur').doc(uid).get();
      final usersDoc = await _firestore.collection('users').doc(uid).get();

      if (utilisateurDoc.exists || usersDoc.exists) {
        setState(() {
          _userData = {
            ...?usersDoc.data(),
            ...?utilisateurDoc.data(),
          };
          _nom = _userData!['nom'];
          _ville = _userData!['ville'];
          _telephone = _userData!['telephone'];
          _photoUrl = _userData!['photoUrl'];
        });
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickAndUploadImage(bool isOffline) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      if (!isOffline) {
        final response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
        );
        setState(() => _photoUrl = response.secureUrl);
      } else {
        await _firestore.collection('pending_profile_updates').add({
          'userId': _user!.uid,
          'action': 'upload_image',
          'filePath': image.path,
          'isSynced': false,
          'timestamp': Timestamp.now(),
        });
        setState(() => _photoUrl = image.path); // Display local image
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Image enregistrée localement, synchronisation en attente"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du téléchargement : $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfileChanges(bool isOffline) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      final uid = _user!.uid;
      final data = {
        'nom': _nom,
        'ville': _ville,
        'telephone': _telephone,
        'email': _userData!['email'],
        'photoUrl': _photoUrl,
      };

      if (isOffline) {
        await _firestore.collection('pending_profile_updates').add({
          'userId': uid,
          'action': 'update_profile',
          'data': data,
          'isSynced': false,
          'timestamp': Timestamp.now(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Modifications enregistrées localement, synchronisation en attente"),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        if (_photoUrl != null) {
          await _firestore.collection('users').doc(uid).set({
            'photoUrl': _photoUrl,
            'email': _userData!['email'],
          }, SetOptions(merge: true));
        }
        await _firestore.collection('utilisateur').doc(uid).set(data, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil mis à jour avec succès"),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() => _isEditing = false);
      await _getUserData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour : $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double avatarRadius = screenWidth * 0.15; // ~54-60 dp
    final double buttonHeight = baseFontSize * 3; // ~48 dp

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          "Profil",
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
        actions: [
          if (!_isLoading && !_isEditing)
            IconButton(
              icon: Icon(Icons.edit, size: baseFontSize * 1.5, color: Colors.white),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Modifier',
            ),
        ],
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
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.green))
                      : _userData == null
                          ? Center(
                              child: Text(
                                "Aucune information trouvée",
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.9 * textScaleFactor,
                                  color: Colors.green[700],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _getUserData,
                              color: Colors.green[700],
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.all(basePadding * 2),
                                child: _isEditing
                                    ? _buildEditForm(isOffline)
                                    : _buildProfileView(),
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

  Widget _buildProfileView() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double avatarRadius = screenWidth * 0.15;

    return Column(
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundImage: _photoUrl != null
              ? (_photoUrl!.startsWith('http')
                  ? NetworkImage(_photoUrl!)
                  : FileImage(File(_photoUrl!)) as ImageProvider)
              : null,
          backgroundColor: Colors.green[200],
          child: _photoUrl == null
              ? Icon(Icons.person, size: avatarRadius * 0.8, color: Colors.white)
              : null,
        ),
        SizedBox(height: basePadding * 2),
        _buildInfoTile(Icons.person, "Nom", _nom),
        _buildInfoTile(Icons.email, "Email", _userData!['email']),
        _buildInfoTile(Icons.phone, "Téléphone", _telephone),
        _buildInfoTile(Icons.location_city, "Ville", _ville),
        SizedBox(height: basePadding * 2),
        OutlinedButton.icon(
          onPressed: () async {
            await _auth.signOut();
            Navigator.pushReplacementNamed(context, '/connexion');
          },
          icon: Icon(Icons.logout, color: Colors.red, size: baseFontSize * 1.5),
          label: Text(
            "Se déconnecter",
            style: GoogleFonts.lato(
              color: Colors.red,
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: EdgeInsets.symmetric(
              horizontal: basePadding * 2,
              vertical: basePadding * 0.8,
            ),
            minimumSize: Size(double.infinity, baseFontSize * 3),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm(bool isOffline) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double avatarRadius = screenWidth * 0.15;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickAndUploadImage(isOffline),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundImage: _photoUrl != null
                  ? (_photoUrl!.startsWith('http')
                      ? NetworkImage(_photoUrl!)
                      : FileImage(File(_photoUrl!)) as ImageProvider)
                  : null,
              backgroundColor: Colors.green[200],
              child: _photoUrl == null
                  ? Icon(Icons.person, size: avatarRadius * 0.8, color: Colors.white)
                  : null,
            ),
          ),
          SizedBox(height: basePadding * 2),
          _buildTextField(
            label: "Nom",
            initialValue: _nom,
            onSaved: (val) => _nom = val,
          ),
          _buildTextField(
            label: "Ville",
            initialValue: _ville,
            onSaved: (val) => _ville = val,
          ),
          _buildTextField(
            label: "Téléphone",
            initialValue: _telephone,
            keyboardType: TextInputType.phone,
            onSaved: (val) => _telephone = val,
          ),
          SizedBox(height: basePadding * 2),
          ElevatedButton.icon(
            onPressed: () => _saveProfileChanges(isOffline),
            icon: Icon(Icons.save, size: baseFontSize * 1.5),
            label: Text(
              "Enregistrer les modifications",
              style: GoogleFonts.lato(
                fontSize: baseFontSize * 0.9 * textScaleFactor,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: basePadding * 2,
                vertical: basePadding * 0.8,
              ),
              minimumSize: Size(double.infinity, baseFontSize * 3),
            ),
          ),
          SizedBox(height: basePadding),
          TextButton(
            onPressed: () => setState(() => _isEditing = false),
            child: Text(
              "Annuler",
              style: GoogleFonts.lato(
                color: Colors.red,
                fontSize: baseFontSize * 0.9 * textScaleFactor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    TextInputType? keyboardType,
    required void Function(String?) onSaved,
  }) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: basePadding),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          labelStyle: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
        ),
        keyboardType: keyboardType,
        style: GoogleFonts.lato(fontSize: baseFontSize * 0.9 * textScaleFactor),
        validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String? value) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;

    return Card(
      margin: EdgeInsets.symmetric(vertical: baseFontSize * 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 3,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: baseFontSize, vertical: baseFontSize * 0.5),
        leading: Icon(icon, color: Colors.green[800], size: baseFontSize * 1.5),
        title: Text(
          label,
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 0.9 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.green[900],
          ),
        ),
        subtitle: Text(
          value ?? 'Non renseigné',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 0.8 * textScaleFactor,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }
}