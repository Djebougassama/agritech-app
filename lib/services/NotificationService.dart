import 'package:cloud_firestore/cloud_firestore.dart';
import '../modeles/NotificationModel.dart';

class NotificationService {
  final CollectionReference _notifRef =
      FirebaseFirestore.instance.collection('notifications');

  Future<void> envoyerNotification(NotificationModel notif) async {
    await _notifRef.add(notif.toMap());
  }

  Stream<List<NotificationModel>> recevoirNotifications(String utilisateurId) {
    return _notifRef
        .where('utilisateurId', isEqualTo: utilisateurId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<void> marquerCommeLue(String notifId) async {
    await _notifRef.doc(notifId).update({'lue': true});
  }
}
