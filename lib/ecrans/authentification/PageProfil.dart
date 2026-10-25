import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_tech_app/ecrans/accueil/accueil_cooperative.dart';

class PageProfil extends StatefulWidget {
  @override
  _PageProfilState createState() => _PageProfilState();
}

class _PageProfilState extends State<PageProfil> {
  final _formKey = GlobalKey<FormState>();
  String? _typeEntreprise;
  String? _ville;
  double? _hectares;
  String? _culturePrincipale;
  String? _telephone;
  String? _nomCooperative; // Ajouté pour nom coopérative
  bool _isLoading = false;

  final List<String> _typesEntreprise = [
    "Agriculteur Professionnel",
    "Coopérative",
  ];

  final List<String> _culturesPrincipales = [
    "Grandes Cultures",
    "Arbres Fruitiers",
    "Légumes",
    "Céréales",
    "Vignes",
  ];

  Future<void> _soumettreProfil() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user == null) throw "Utilisateur non authentifié";

        // Sauvegarde de base dans 'users'
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'typeEntreprise': _typeEntreprise,
          'ville': _ville,
          'hectares': _hectares,
          'culturePrincipale': _culturePrincipale,
          'telephone': _telephone,
        });

        String? cooperativeId;

        if (_typeEntreprise == "Coopérative") {
          if (_nomCooperative == null || _nomCooperative!.isEmpty) {
            throw "Veuillez renseigner le nom de la coopérative";
          }
          // Création du doc coopérative
          DocumentReference docCoop = await FirebaseFirestore.instance.collection('cooperatives').add({
            'userId': user.uid,
            'nom': _nomCooperative,
            'ville': _ville,
            'hectares': _hectares,
            'culturePrincipale': _culturePrincipale,
            'telephone': _telephone,
            'dateCreation': FieldValue.serverTimestamp(),
          });
          cooperativeId = docCoop.id;

          // Mise à jour user avec cooperativeId
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'cooperativeId': cooperativeId,
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil enregistré avec succès !')),
        );

        if (_typeEntreprise == "Agriculteur Professionnel") {
  Navigator.pushReplacementNamed(context, '/ecran_accueil');
} else if (_typeEntreprise == "Coopérative" && cooperativeId != null) {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => AccueilCooperative(cooperativeId: cooperativeId!),
    ),
  );
}


      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 10,
            shadowColor: Colors.black.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Compléter votre profil",
                        style: GoogleFonts.lato(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Type d'entreprise
                    Text("Type d'entreprise", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
                    DropdownButtonFormField<String>(
                      value: _typeEntreprise,
                      items: _typesEntreprise.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.lato(color: Colors.green.shade800)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _typeEntreprise = value;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.business, color: Colors.green.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null ? "Ce champ est requis" : null,
                    ),
                    SizedBox(height: 20),

                    // Nom coopérative — afficher uniquement si type = Coopérative
                    if (_typeEntreprise == "Coopérative") ...[
                      Text("Nom de la coopérative", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
                      TextFormField(
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.apartment, color: Colors.green.shade700),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => _nomCooperative = value,
                        validator: (value) {
                          if (_typeEntreprise == "Coopérative" && (value == null || value.isEmpty)) {
                            return "Ce champ est requis";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                    ],

                    // Ville
                    Text("Ville", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
                    TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.location_city, color: Colors.green.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _ville = value,
                      validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
                    ),
                    SizedBox(height: 20),

                    // Superficie totale
                    Text("Superficie totale (en hectares)", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
                    TextFormField(
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.landscape, color: Colors.green.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _hectares = double.tryParse(value),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Ce champ est requis";
                        final parsed = double.tryParse(value);
                        if (parsed == null) return "Entrez un nombre valide";
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Culture principale
                    Text("Culture principale", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
                    DropdownButtonFormField<String>(
                      value: _culturePrincipale,
                      items: _culturesPrincipales.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.lato(color: Colors.green.shade800)),
                        );
                      }).toList(),
                      onChanged: (value) => _culturePrincipale = value,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.eco, color: Colors.green.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) => value == null ? "Ce champ est requis" : null,
                    ),
                    SizedBox(height: 20),

                    // Numéro de téléphone
                    Text("Numéro de téléphone", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
                    TextFormField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.phone, color: Colors.green.shade700),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => _telephone = value,
                      validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
                    ),
                    SizedBox(height: 30),

                    // Bouton d'enregistrement
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _soumettreProfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 6,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text("Enregistrer et continuer", style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
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

// class PageProfil extends StatefulWidget {
//   @override
//   _PageProfilState createState() => _PageProfilState();
// }

// class _PageProfilState extends State<PageProfil> {
//   final _formKey = GlobalKey<FormState>();
//   String? _typeEntreprise;
//   String? _ville;
//   double? _hectares;
//   String? _culturePrincipale;
//   String? _telephone;
//   bool _isLoading = false;

//   final List<String> _typesEntreprise = [
//     "Agriculteur Professionnel",
//     "Coopérative",
//   ];

//   final List<String> _culturesPrincipales = [
//     "Grandes Cultures",
//     "Arbres Fruitiers",
//     "Légumes",
//     "Céréales",
//     "Vignes",
//   ];

//   Future<void> _soumettreProfil() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         User? user = FirebaseAuth.instance.currentUser;
//         if (user == null) throw "Utilisateur non authentifié";

//         await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//           'typeEntreprise': _typeEntreprise,
//           'ville': _ville,
//           'hectares': _hectares,
//           'culturePrincipale': _culturePrincipale,
//           'telephone': _telephone,
//         });

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Profil enregistré avec succès !')),
//         );

//         if (_typeEntreprise == "Agriculteur Professionnel") {
//           Navigator.pushReplacementNamed(context, '/ecran_accueil');
//         } else if (_typeEntreprise == "Coopérative") {
//           Navigator.pushReplacementNamed(context, '/accueil_cooperative');
//         }

//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Erreur : $e')),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//             ),
//           ),
//           padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
//           child: Card(
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//             elevation: 10,
//             shadowColor: Colors.black.withOpacity(0.2),
//             child: Padding(
//               padding: const EdgeInsets.all(25),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Text(
//                         "Compléter votre profil",
//                         style: GoogleFonts.lato(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.green.shade800,
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20),

//                     // Type d'entreprise
//                     Text("Type d'entreprise", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
//                     DropdownButtonFormField<String>(
//                       value: _typeEntreprise,
//                       items: _typesEntreprise.map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value, style: GoogleFonts.lato(color: Colors.green.shade800)),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         setState(() {
//                           _typeEntreprise = value;
//                         });
//                       },
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.business, color: Colors.green.shade700),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       validator: (value) => value == null ? "Ce champ est requis" : null,
//                     ),
//                     SizedBox(height: 20),

//                     // Ville
//                     Text("Ville", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
//                     TextFormField(
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.location_city, color: Colors.green.shade700),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       onChanged: (value) => _ville = value,
//                       validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
//                     ),
//                     SizedBox(height: 20),

//                     // Superficie totale
//                     Text("Superficie totale (en hectares)", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
//                     TextFormField(
//                       keyboardType: TextInputType.numberWithOptions(decimal: true),
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.landscape, color: Colors.green.shade700),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       onChanged: (value) => _hectares = double.tryParse(value),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) return "Ce champ est requis";
//                         final parsed = double.tryParse(value);
//                         if (parsed == null) return "Entrez un nombre valide";
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),

//                     // Culture principale
//                     Text("Culture principale", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
//                     DropdownButtonFormField<String>(
//                       value: _culturePrincipale,
//                       items: _culturesPrincipales.map((String value) {
//                         return DropdownMenuItem<String>(
//                           value: value,
//                           child: Text(value, style: GoogleFonts.lato(color: Colors.green.shade800)),
//                         );
//                       }).toList(),
//                       onChanged: (value) => _culturePrincipale = value,
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.eco, color: Colors.green.shade700),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       validator: (value) => value == null ? "Ce champ est requis" : null,
//                     ),
//                     SizedBox(height: 20),

//                     // Numéro de téléphone
//                     Text("Numéro de téléphone", style: GoogleFonts.lato(fontSize: 16, color: Colors.green.shade800)),
//                     TextFormField(
//                       keyboardType: TextInputType.phone,
//                       decoration: InputDecoration(
//                         prefixIcon: Icon(Icons.phone, color: Colors.green.shade700),
//                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//                         filled: true,
//                         fillColor: Colors.white,
//                       ),
//                       onChanged: (value) => _telephone = value,
//                       validator: (value) => value!.isEmpty ? "Ce champ est requis" : null,
//                     ),
//                     SizedBox(height: 30),

//                     // Bouton d'enregistrement
//                     Center(
//                       child: ElevatedButton(
//                         onPressed: _isLoading ? null : _soumettreProfil,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green.shade700,
//                           padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
//                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                           elevation: 6,
//                         ),
//                         child: _isLoading
//                             ? CircularProgressIndicator(color: Colors.white)
//                             : Text("Enregistrer et continuer", style: GoogleFonts.lato(fontSize: 18, color: Colors.white)),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
