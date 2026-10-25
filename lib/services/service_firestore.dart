import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/agriculteur_modele.dart';
import 'package:agri_tech_app/modeles/culture.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ajouter un agriculteur
  Future<void> ajouterAgriculteur(Agriculteur agriculteur) async {
    await _firestore.collection('Agriculteurs').doc(agriculteur.id).set(agriculteur.toMap());
  }

  // Récupérer tous les agriculteurs
  Future<List<Agriculteur>> obtenirAgriculteurs() async {
    QuerySnapshot querySnapshot = await _firestore.collection('Agriculteurs').get();
    return querySnapshot.docs.map((doc) => Agriculteur.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  // Ajouter une culture
  Future<void> ajouterCulture(Culture culture) async {
    await _firestore.collection('Cultures').doc(culture.id).set(culture.toMap());
  }

  // Récupérer toutes les cultures d'un agriculteur
  Future<List<Culture>> obtenirCultures(String agriculteurId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('Cultures')
        .where('agriculteurId', isEqualTo: agriculteurId)
        .get();
    return querySnapshot.docs.map((doc) => Culture.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
  }

  
  Future<void> saveProfileData(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('profils').add(data);
  }
}
