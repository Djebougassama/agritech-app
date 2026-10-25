import 'package:cloud_firestore/cloud_firestore.dart';

class Stock {
  final String id; // Nouvel identifiant unique
  final String cooperativeId;
  final DateTime derniereMiseAJour;
  final String produit;
  final int quantite;
  final String unite;

  Stock({
    required this.id,
    required this.cooperativeId,
    required this.derniereMiseAJour,
    required this.produit,
    required this.quantite,
    required this.unite,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cooperativeId': cooperativeId,
      'derniereMiseAJour': derniereMiseAJour,
      'produit': produit,
      'quantite': quantite,
      'unite': unite,
    };
  }

  factory Stock.fromFirestore(Map<String, dynamic> data, String id) {
    return Stock(
      id: id,
      cooperativeId: data['cooperativeId'] ?? '',
      derniereMiseAJour: (data['derniereMiseAJour'] as Timestamp?)?.toDate() ?? DateTime.now(),
      produit: data['produit'] ?? 'Inconnu',
      quantite: (data['quantite'] ?? 0).toInt(),
      unite: data['unite'] ?? 'sacs',
    );
  }
}