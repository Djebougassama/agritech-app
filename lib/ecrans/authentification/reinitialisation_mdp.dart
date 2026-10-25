import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class EcranReinitialisationMotDePasse extends StatefulWidget {
  @override
  _EcranReinitialisationMotDePasseState createState() =>
      _EcranReinitialisationMotDePasseState();
}

class _EcranReinitialisationMotDePasseState
    extends State<EcranReinitialisationMotDePasse> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _reinitialiserMotDePasse() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text("Email de réinitialisation envoyé !"),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text("Erreur : ${e.toString()}"),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Réinitialisation du mot de passe"),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 12,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_reset, size: 80, color: Colors.green),
                        const SizedBox(height: 10),
                        Text(
                          "Réinitialiser le mot de passe",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Entrez votre adresse email pour recevoir un lien de réinitialisation.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.lato(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 25),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration("Email", Icons.email),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Ce champ est requis";
                            } else if (!RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                .hasMatch(value)) {
                              return "Entrez un email valide";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _reinitialiserMotDePasse,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Envoyer le lien",
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.arrow_back, color: Colors.green),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/connexion');
                              },
                              child: Text(
                                "Retour à la connexion",
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                          ],
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
