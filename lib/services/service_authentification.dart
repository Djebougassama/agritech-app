import 'package:firebase_auth/firebase_auth.dart';

class ServiceAuthentification {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Inscription
  Future<User?> inscrireUtilisateur(String email, String motDePasse) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      return userCredential.user;
    } catch (e) {
      print("Erreur d'inscription : $e");
      return null;
    }
  }

  // 🔹 Connexion
  Future<User?> connecterUtilisateur(String email, String motDePasse) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: motDePasse,
      );
      return userCredential.user;
    } catch (e) {
      print("Erreur de connexion : $e");
      return null;
    }
  }

  // 🔹 Déconnexion
  Future<void> deconnecterUtilisateur() async {
    await _auth.signOut();
  }

  // 🔹 Récupérer l'utilisateur actuel
  User? obtenirUtilisateurActuel() {
    return _auth.currentUser;
  }

  // 🔹 Écoute l’état de connexion
  Stream<User?> suivreEtatUtilisateur() {
    return _auth.authStateChanges();
  }
  
  // 🔹 Envoi d'un email pour réinitialiser le mot de passe
  Future<void> reinitialiserMotDePasse(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("Email de réinitialisation envoyé !");
    } catch (e) {
      print("Erreur : $e");
    }
  }
}
