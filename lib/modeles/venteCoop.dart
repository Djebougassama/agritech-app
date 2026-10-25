
// Modèle Vente (à créer dans models/vente.dart)
class Vente {
  final String id;
  final String produit;
  final int quantite;
  final int prix;
  final String statut;
  final DateTime date;

  Vente({
    required this.id,
    required this.produit,
    required this.quantite,
    required this.prix,
    required this.statut,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit': produit,
      'quantite': quantite,
      'prix': prix,
      'statut': statut,
      'date': date,
      'unite': 'tonnes', // Par défaut, ajustable
    };
  }
}