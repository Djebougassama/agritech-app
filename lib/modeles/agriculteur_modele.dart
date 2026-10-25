import 'package:cloud_firestore/cloud_firestore.dart';

class Agriculteur {
  String id;
  String nom;
  String email;
  String localisation;

  Agriculteur({
    required this.id,
    required this.nom,
    required this.email,
    required this.localisation,
  });

  // Convertir un Agriculteur en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'email': email,
      'localisation': localisation,
    };
  }

  // Créer un Agriculteur à partir d'un Map de Firestore
  factory Agriculteur.fromMap(Map<String, dynamic> data) {
    return Agriculteur(
      id: data['id'],
      nom: data['nom'],
      email: data['email'],
      localisation: data['localisation'],
    );
  }
}