import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String titre;
  final String message;
  final String type; // météo, culture, vente, etc.
  final DateTime date;
  final bool lue;
  final String utilisateurId;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.type,
    required this.date,
    required this.lue,
    required this.utilisateurId,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String docId) {
    return NotificationModel(
      id: docId,
      titre: map['titre'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      lue: map['lue'] ?? false,
      utilisateurId: map['utilisateurId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titre': titre,
      'message': message,
      'type': type,
      'date': date,
      'lue': lue,
      'utilisateurId': utilisateurId,
    };
  }
}
