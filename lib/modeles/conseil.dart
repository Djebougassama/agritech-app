import 'package:cloud_firestore/cloud_firestore.dart';


class Conseil {
  final String id;
  final String titre;
  final String description;
  final String categorie;
  final DateTime datePublication;
  final List<String>? tags; // ✅ Ajout du champ tags

  Conseil({
    required this.id,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.datePublication,
    this.tags,
  });

  factory Conseil.fromMap(String id, Map<String, dynamic> data) {
    return Conseil(
      id: id,
      titre: data['titre'] ?? '',
      description: data['description'] ?? '',
      categorie: data['categorie'] ?? '',
      datePublication: DateTime.tryParse(data['datePublication'] ?? '') ?? DateTime.now(),
      tags: data['tags'] != null
          ? List<String>.from(data['tags'])
          : [], // ✅ chargement de tags
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'description': description,
      'categorie': categorie,
      'datePublication': datePublication.toIso8601String(),
      'tags': tags ?? [], // ✅ enregistrement de tags
    };
  }
}
