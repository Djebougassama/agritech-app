import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PageInscription extends StatefulWidget {
  const PageInscription({super.key});

  @override
  _PageInscriptionState createState() => _PageInscriptionState();
}

class _PageInscriptionState extends State<PageInscription> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motDePasseController = TextEditingController();
  bool _motDePasseVisible = false;

  Future<void> _inscrireUtilisateur() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _motDePasseController.text.trim(),
        );

        String uid = userCredential.user!.uid;

        await FirebaseFirestore.instance.collection('utilisateur').doc(uid).set({
          'nom': _nomController.text.trim(),
          'email': _emailController.text.trim(),
        });

        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'ville': '',
          'telephone': '',
          'photoUrl': '',
          'typeEntreprise': 'Agriculteur Professionnel',
          'culturePrincipale': '',
          'hectares': 0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inscription réussie !"), backgroundColor: Colors.green),
        );

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushNamed(context, '/PageProfil');
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur : ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false}) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.green.shade700, size: isSmallScreen ? 20 : 24),
      labelText: label,
      labelStyle: GoogleFonts.lato(
        color: Colors.green.shade800, 
        fontSize: isSmallScreen ? 14 : 16
      ),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        borderSide: BorderSide(color: Colors.green.shade700, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 25),
        borderSide: BorderSide(color: Colors.green.shade300, width: 1),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                _motDePasseVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.green.shade700,
                size: isSmallScreen ? 20 : 24,
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 30,
                vertical: isSmallScreen ? 10 : 0
              ),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 20 : 30),
                ),
                elevation: 12,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.agriculture, 
                          size: isSmallScreen ? 60 : 80, 
                          color: Colors.green.shade700
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 10),
                        Text(
                          "Créer un compte",
                          style: GoogleFonts.lato(
                            fontSize: isSmallScreen ? 22 : 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        TextFormField(
                          controller: _nomController,
                          decoration: _inputDecoration("Nom", Icons.person),
                          validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 15),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Email", Icons.email),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Ce champ est requis";
                            } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                              return "Entrez un email valide";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 15),
                        TextFormField(
                          controller: _motDePasseController,
                          obscureText: !_motDePasseVisible,
                          decoration: _inputDecoration("Mot de passe", Icons.lock, isPassword: true),
                          validator: (value) => value!.length < 6 ? "Au moins 6 caractères" : null,
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _inscrireUtilisateur,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallScreen ? 12 : 15,
                                horizontal: isSmallScreen ? 16 : 24
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                              ),
                              elevation: 6,
                            ),
                            child: Text(
                              "S'inscrire", 
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18, 
                                color: Colors.white
                              )
                            ),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 15 : 20),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/connexion');
                            },
                            child: Text(
                              "Déjà un compte ? Se connecter",
                              style: GoogleFonts.lato(
                                fontSize: isSmallScreen ? 14 : 16, 
                                fontWeight: FontWeight.w600, 
                                color: Colors.green.shade800
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}