import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agri_tech_app/modeles/formation_modele.dart';

class FormationService {
  final CollectionReference formationsCollection =
      FirebaseFirestore.instance.collection('formations');

  // Récupérer toutes les formations
  Future<List<Formation>> getFormations() async {
    try {
      QuerySnapshot querySnapshot = await formationsCollection.get();
      return querySnapshot.docs
          .map((doc) => Formation.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print("Erreur lors de la récupération des formations : $e");
      return [];
    }
  }

   Future<void> ajouterFormation(
    String titre, String description, String imageUrl, String videoUrl) async {
  await formationsCollection.add({ // Ajout de 'await' ici
    'titre': titre,
    'description': description,
    'imageUrl': imageUrl,
    'videoUrl': videoUrl,
    'datePublication': DateTime.now().toIso8601String(),
  });
}


  // Récupérer une formation spécifique par ID
  Future<Formation?> getFormationById(String id) async {
    try {
      DocumentSnapshot doc = await formationsCollection.doc(id).get();
      if (doc.exists) {
        return Formation.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Erreur lors de la récupération de la formation : $e");
      return null;
    }
  }
}
