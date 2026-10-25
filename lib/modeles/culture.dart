import 'package:cloud_firestore/cloud_firestore.dart';


class Culture {
  final String id;
  final String nom;
  final String type;
  final double superficie;
  final String agriculteurId;
  final DateTime datePlantation;
  final DateTime dateRecolte;
  final double rendement;

  Culture({
    required this.id,
    required this.nom,
    required this.type,
    required this.superficie,
    required this.agriculteurId,
    required this.datePlantation,
    required this.dateRecolte,
    required this.rendement,
  });

  factory Culture.fromMap(String id, Map<String, dynamic> map) {
    return Culture(
      id: id,
      nom: map['nom'] ?? '',
      type: map['type'] ?? '',
      superficie: (map['superficie'] ?? 0).toDouble(),
      agriculteurId: map['userId'] ?? '',
      datePlantation: (map['datePlantation'] as Timestamp).toDate(),
      dateRecolte: (map['dateRecolte'] as Timestamp).toDate(),
      rendement: (map['rendement'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'type': type,
      'superficie': superficie,
      'userId': agriculteurId,
      'datePlantation': datePlantation,
      'dateRecolte': dateRecolte,
      'rendement': rendement,
    };
  }
}
