class Rapport {
  String id;
  String type; // "culture", "vente", "stock", "formation", "activite_collective"
  DateTime dateGeneration;
  String contenu;
  String utilisateurId; // pour filtrer selon l'utilisateur connecté

  Rapport({
    required this.id,
    required this.type,
    required this.dateGeneration,
    required this.contenu,
    required this.utilisateurId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'dateGeneration': dateGeneration.toIso8601String(),
      'contenu': contenu,
      'utilisateurId': utilisateurId,
    };
  }

  factory Rapport.fromMap(Map<String, dynamic> map) {
    return Rapport(
      id: map['id'],
      type: map['type'],
      dateGeneration: DateTime.parse(map['dateGeneration']),
      contenu: map['contenu'],
      utilisateurId: map['utilisateurId'],
    );
  }
}
