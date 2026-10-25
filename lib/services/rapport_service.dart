import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_tech_app/modeles/rapport.dart';

class RapportService {
  final CollectionReference rapportsCollection =
      FirebaseFirestore.instance.collection('rapports');

  Future<void> ajouterRapport(Rapport rapport) async {
    await rapportsCollection.doc(rapport.id).set(rapport.toMap());
  }

  Future<List<Rapport>> getRapportsParType(String utilisateurId, String type) async {
    final snapshot = await rapportsCollection
        .where('utilisateurId', isEqualTo: utilisateurId)
        .where('type', isEqualTo: type)
        .orderBy('dateGeneration', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Rapport.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }
}
