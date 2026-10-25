import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

Future<void> creerNotificationsAutomatiques(Map<String, dynamic> cultureData) async {
  final cultureNom = cultureData['nom'];
  final datePlantation = (cultureData['datePlantation'] as Timestamp).toDate();
  final userId = cultureData['userId'];

  final refSnapshot = await FirebaseFirestore.instance
      .collection('cultures_reference')
      .where('nom', isEqualTo: cultureNom)
      .limit(1)
      .get();

  if (refSnapshot.docs.isEmpty) return;

  final ref = refSnapshot.docs.first.data();
  final frequenceArrosage = ref['frequence_arrosage_par_jour'] ?? 1;
  final delaiRecolte = ref['delai_recolte_jours'] ?? 90;

  // 🔁 Notifications d’arrosage (7 jours)
  for (int i = 0; i < 7; i++) {
    final date = datePlantation.add(Duration(days: i));
    for (int j = 0; j < frequenceArrosage; j++) {
      final heure = 7 + j * 6;
      final dateNotif = DateTime(date.year, date.month, date.day, heure);
      await ServiceNotifications.notifierRappelCultureArrosage(
        userId: userId,
        culture: cultureNom,
        date: dateNotif,
      );
    }
  }

  // 📅 Notification de récolte
  final dateRecolteEstimee = datePlantation.add(Duration(days: delaiRecolte));
  await ServiceNotifications.notifierRappelCultureRecolte(
    userId: userId,
    culture: cultureNom,
    date: dateRecolteEstimee,
  );
}
