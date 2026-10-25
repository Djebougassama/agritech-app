import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> migrerAnciennesNotifications() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    final anciennesNotifs = await firestore.collection('notifications').get();

    for (final doc in anciennesNotifs.docs) {
      final data = doc.data();
      final userId = data['userId'];

      if (userId == null) {
        print("❌ Notification ignorée (userId manquant) : ${doc.id}");
        continue;
      }

      // Ajout dans la sous-collection de l'utilisateur
      await firestore
          .collection('utilisateurs')
          .doc(userId)
          .collection('notifications')
          .add({
        'titre': data['titre'],
        'message': data['message'],
        'type': data['type'],
        'date': data['date'],
        'lu': data['lu'] ?? false,
      });

      print("✅ Notification migrée pour l'utilisateur $userId : ${data['titre']}");
    }

    print("🎉 Migration terminée avec succès !");
  } catch (e) {
    print("⚠️ Erreur pendant la migration : $e");
  }
}
