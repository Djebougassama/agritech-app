
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class PageModifierProfil extends StatefulWidget {
  const PageModifierProfil({super.key});

  @override
  _PageModifierProfilState createState() => _PageModifierProfilState();
}

class _PageModifierProfilState extends State<PageModifierProfil> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryPublic cloudinary = CloudinaryPublic('djlvibqqc', 'AgriTech', cache: false);

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _motDePasseVisible = false;
  bool _isLoading = false;
  late User? _user;
  Map<String, dynamic>? _userData; // Change to nullable type

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _getUserData();
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    if (_user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _nomController.text = _userData!['nom'];
          _emailController.text = _userData!['email'];
        });
      }
    }
  }

  // Upload image to Cloudinary
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      
      String imageUrl = response.secureUrl;
      await _firestore.collection('users').doc(_user!.uid).update({'photoUrl': imageUrl});
      
      setState(() {
        _userData!['photoUrl'] = imageUrl;
      });
    } catch (e) {
      print("Erreur lors du téléchargement : $e");
    }
  }

  // Update profile information in Firestore
  Future<void> _mettreAJourProfil() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _firestore.collection('users').doc(_user!.uid).update({
          'nom': _nomController.text.trim(),
          'email': _emailController.text.trim(),
          // Ajoute d'autres champs si nécessaire
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour !"), backgroundColor: Colors.green),
        );
        
        setState(() {
          _isLoading = false;
        });

        // Return to the previous screen
        Navigator.pop(context); 
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Input field decoration
  InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.green.shade700),
      labelText: label,
      labelStyle: GoogleFonts.lato(color: Colors.green.shade800, fontSize: 16),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: Colors.green.shade300, width: 1),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _motDePasseVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.green.shade700,
              ),
              onPressed: () {
                setState(() {
                  _motDePasseVisible = !_motDePasseVisible;
                });
              },
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Modifier le Profil",
          style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _userData!['photoUrl'] != null
                            ? NetworkImage(_userData!['photoUrl'])
                            : null,
                        backgroundColor: Colors.green.shade300,
                        child: _userData!['photoUrl'] == null
                            ? const Icon(Icons.camera_alt, size: 60, color: Colors.black)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nomController,
                      decoration: _inputDecoration("Nom", Icons.person),
                      validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration("Email", Icons.email),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "Ce champ est requis";
                        } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                          return "Entrez un email valide";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _mettreAJourProfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 6,
                      ),
                      child: const Text("Mettre à jour", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
