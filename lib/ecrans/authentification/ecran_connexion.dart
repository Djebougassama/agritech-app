import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_tech_app/ecrans/accueil/accueil_cooperative.dart';



class EcranConnexion extends StatefulWidget {
  @override
  _EcranConnexionState createState() => _EcranConnexionState();
}

class _EcranConnexionState extends State<EcranConnexion> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _motDePasseVisible = false;

  Future<void> signIn(String email, String password) async {
  setState(() {
    _isLoading = true;
  });

  try {
    UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = userCredential.user!.uid;

    // 🔥 On récupère l'utilisateur depuis Firestore
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data();
      final typeEntreprise = data?['typeEntreprise'] ?? '';

      // 🔄 Redirection selon le type
      if (typeEntreprise == "Coopérative") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AccueilCooperative(cooperativeId: data?['cooperativeId']),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/ecran_accueil');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Utilisateur non trouvé dans Firestore")),
      );
    }
  } on FirebaseAuthException catch (e) {
    print('Erreur : ${e.message}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur : ${e.message}'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


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
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 12,
                shadowColor: Colors.black26,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.agriculture, size: 80, color: Colors.green.shade700),
                      const SizedBox(height: 10),
                      Text(
                        "Connexion",
                        style: GoogleFonts.lato(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration("Email", Icons.email),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Ce champ est requis";
                          } else if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+\$').hasMatch(value)) {
                            return "Entrez un email valide";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !_motDePasseVisible,
                        decoration: _inputDecoration("Mot de passe", Icons.lock, isPassword: true),
                        validator: (value) => value!.length < 6 ? "Au moins 6 caractères" : null,
                      ),
                      const SizedBox(height: 10),
                      // Bouton "Mot de passe oublié"
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/reinitialisation-mdp');
                          },
                          child: Text(
                            "Mot de passe oublié ?",
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
                              signIn(emailController.text, passwordController.text);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Veuillez remplir tous les champs'),
                                  backgroundColor: Colors.orange.shade700,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 6,
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : const Text("Se connecter", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Bouton "Pas de compte ? S'inscrire"
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/inscription');
                          },
                          child: Text(
                            "Pas de compte ? S'inscrire",
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
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
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:agri_tech_app/ecrans/accueil/accueil_cooperative.dart';

// class EcranConnexion extends StatefulWidget {
//   @override
//   _EcranConnexionState createState() => _EcranConnexionState();
// }

// class _EcranConnexionState extends State<EcranConnexion> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   bool _isLoading = false;
//   bool _motDePasseVisible = false;
//   bool _isOffline = false;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   @override
//   void initState() {
//     super.initState();
//     _monitorConnectivity();
//   }

//   // 🔍 Surveiller la connectivité
//   void _monitorConnectivity() {
//     Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
//       if (mounted) {
//         setState(() {
//           _isOffline = results.isEmpty || results.first == ConnectivityResult.none;
//         });
//       }
//     });
//   }

//   Future<void> signIn(String email, String password) async {
//     if (_isOffline) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Connexion requise pour vous connecter."),
//           backgroundColor: Colors.red,
//         ),
//       );
//       setState(() => _isLoading = false);
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       final uid = userCredential.user!.uid;

//       // 🔥 Récupérer les données de l'utilisateur depuis Firestore (utilisation du cache si hors ligne)
//       final doc = await _firestore.collection('users').doc(uid).get(const GetOptions(source: Source.cache));

//       if (doc.exists) {
//         final data = doc.data();
//         final typeEntreprise = data?['typeEntreprise'] ?? '';

//         // 🔄 Redirection selon le type
//         if (typeEntreprise == "Coopérative") {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => AccueilCooperative(cooperativeId: data?['cooperativeId']),
//             ),
//           );
//         } else {
//           Navigator.pushReplacementNamed(context, '/ecran_accueil');
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Utilisateur non trouvé dans Firestore")),
//         );
//       }
//     } on FirebaseAuthException catch (e) {
//       print('Erreur : ${e.message}');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Erreur : ${e.message}'),
//           backgroundColor: Colors.red.shade700,
//         ),
//       );
//     } catch (e) {
//       print('Erreur inattendue : $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text("Une erreur s'est produite. Vérifiez votre connexion."),
//           backgroundColor: Colors.red.shade700,
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   InputDecoration _inputDecoration(String label, IconData icon, {bool isPassword = false}) {
//     return InputDecoration(
//       prefixIcon: Icon(icon, color: Colors.green.shade700),
//       labelText: label,
//       labelStyle: GoogleFonts.lato(color: Colors.green.shade800, fontSize: 16),
//       filled: true,
//       fillColor: Colors.white,
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(25),
//         borderSide: BorderSide(color: Colors.green.shade700, width: 2),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(25),
//         borderSide: BorderSide(color: Colors.green.shade300, width: 1),
//       ),
//       suffixIcon: isPassword
//           ? IconButton(
//               icon: Icon(
//                 _motDePasseVisible ? Icons.visibility : Icons.visibility_off,
//                 color: Colors.green.shade700,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _motDePasseVisible = !_motDePasseVisible;
//                 });
//               },
//             )
//           : null,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         width: double.infinity,
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 30),
//               child: Card(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(30),
//                 ),
//                 elevation: 12,
//                 shadowColor: Colors.black26,
//                 child: Padding(
//                   padding: const EdgeInsets.all(30),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.center,
//                     children: [
//                       Icon(Icons.agriculture, size: 80, color: Colors.green.shade700),
//                       const SizedBox(height: 10),
//                       Text(
//                         "Connexion",
//                         style: GoogleFonts.lato(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green.shade800,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       TextFormField(
//                         controller: emailController,
//                         keyboardType: TextInputType.emailAddress,
//                         decoration: _inputDecoration("Email", Icons.email),
//                         enabled: !_isOffline,
//                       ),
//                       const SizedBox(height: 15),
//                       TextFormField(
//                         controller: passwordController,
//                         obscureText: !_motDePasseVisible,
//                         decoration: _inputDecoration("Mot de passe", Icons.lock, isPassword: true),
//                         enabled: !_isOffline,
//                       ),
//                       const SizedBox(height: 10),
//                       Align(
//                         alignment: Alignment.centerRight,
//                         child: TextButton(
//                           onPressed: _isOffline ? null : () {
//                             Navigator.pushNamed(context, '/reinitialisation-mdp');
//                           },
//                           child: Text(
//                             "Mot de passe oublié ?",
//                             style: GoogleFonts.lato(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green.shade800,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: _isOffline || _isLoading
//                               ? null
//                               : () {
//                                   if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
//                                     signIn(emailController.text, passwordController.text);
//                                   } else {
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       SnackBar(
//                                         content: Text('Veuillez remplir tous les champs'),
//                                         backgroundColor: Colors.orange,
//                                         behavior: SnackBarBehavior.floating,
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(10),
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                 },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.green.shade700,
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             elevation: 6,
//                           ),
//                           child: _isLoading
//                               ? CircularProgressIndicator(color: Colors.white)
//                               : const Text("Se connecter", style: TextStyle(fontSize: 18, color: Colors.white)),
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                       Center(
//                         child: TextButton(
//                           onPressed: _isOffline ? null : () {
//                             Navigator.pushNamed(context, '/inscription');
//                           },
//                           child: Text(
//                             "Pas de compte ? S'inscrire",
//                             style: GoogleFonts.lato(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.green.shade800,
//                             ),
//                           ),
//                         ),
//                       ),
//                       if (_isOffline)
//                         const Padding(
//                           padding: EdgeInsets.only(top: 20),
//                           child: Text(
//                             "🚫 Connexion requise pour vous connecter.",
//                             style: TextStyle(color: Colors.red, fontSize: 14),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }