import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:agri_tech_app/modeles/rapport.dart';

class GenerateurRapportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Rapport> genererRapportCulture(String utilisateurId) async {
    final snapshot = await _firestore
        .collection('cultures')
        .where('userId', isEqualTo: utilisateurId)
        .get();

    final cultures = snapshot.docs;

    if (cultures.isEmpty) {
      return Rapport(
        id: Uuid().v4(),
        type: 'culture',
        dateGeneration: DateTime.now(),
        contenu: 'Aucune culture enregistrée.',
        utilisateurId: utilisateurId,
      );
    }

    double totalRendement = 0;
    StringBuffer contenu = StringBuffer();
    contenu.writeln(" Rapport de cultures\n");

    for (var doc in cultures) {
      final data = doc.data();
      final nom = data['nom'] ?? 'Inconnu';
      final type = data['type'] ?? 'N/A';
      final plantation = (data['datePlantation'] as Timestamp).toDate();
      final recolte = (data['dateRecolte'] as Timestamp).toDate();
      final rendement = double.tryParse(data['rendement'].toString()) ?? 0;

      totalRendement += rendement;

      contenu.writeln(" Culture : $nom");
      contenu.writeln(" Type : $type");
      contenu.writeln(" Plantation : ${_formatDate(plantation)}");
      contenu.writeln(" Récolte : ${_formatDate(recolte)}");
      contenu.writeln(" Rendement : $rendement tonnes");
      contenu.writeln("----------------------------------");
    }

    double moyenne = totalRendement / cultures.length;
    contenu.writeln(" Total de cultures : ${cultures.length}");
    contenu.writeln(" Rendement moyen : ${moyenne.toStringAsFixed(2)} tonnes");

    return Rapport(
      id: Uuid().v4(),
      type: 'culture',
      dateGeneration: DateTime.now(),
      contenu: contenu.toString(),
      utilisateurId: utilisateurId,
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
