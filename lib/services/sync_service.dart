// lib/services/sync_service.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:developer'; // Added for debugPrint

Future<void> syncPendingData() async {
  final firestore = FirebaseFirestore.instance;
  final cloudinary = CloudinaryPublic('djlvibqqc', 'AgriTech', cache: false);

  try {
    // Sync pending notifications
    final pendingNotifications = await firestore
        .collection('pending_notifications')
        .where('isSynced', isEqualTo: false)
        .get();
    for (var doc in pendingNotifications.docs) {
      final data = doc.data();
      if (data['action'] == 'mark_read') {
        await firestore
            .collection('utilisateurs')
            .doc(data['userId'])
            .collection('notifications')
            .doc(data['notificationId'])
            .update({'lu': true});
      } else {
        await firestore
            .collection('utilisateurs')
            .doc(data['userId'])
            .collection('notifications')
            .add({
              'titre': data['titre'],
              'message': data['message'],
              'type': data['type'],
              'date': data['date'],
              'lu': data['lu'] ?? false,
            });
      }
      await doc.reference.delete();
    }

    // Sync pending profile updates
    final pendingProfileUpdates = await firestore
        .collection('pending_profile_updates')
        .where('isSynced', isEqualTo: false)
        .get();
    for (var doc in pendingProfileUpdates.docs) {
      final data = doc.data();
      final userId = data['userId'];
      if (data['action'] == 'upload_image') {
        final file = File(data['filePath']);
        if (await file.exists()) {
          final response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(data['filePath'], resourceType: CloudinaryResourceType.Image),
          );
          await firestore.collection('users').doc(userId).set({
            'photoUrl': response.secureUrl,
            'email': data['email'] ?? '',
          }, SetOptions(merge: true));
          await file.delete();
        }
      } else if (data['action'] == 'update_profile') {
        final profileData = data['data'];
        await firestore.collection('users').doc(userId).set({
          'photoUrl': profileData['photoUrl'],
          'email': profileData['email'],
        }, SetOptions(merge: true));
        await firestore.collection('utilisateur').doc(userId).set(
          profileData,
          SetOptions(merge: true),
        );
      }
      await doc.reference.delete();
    }

    // Sync pending rapports
    final pendingRapports = await firestore
        .collection('pending_rapports')
        .where('isSynced', isEqualTo: false)
        .get();
    for (var doc in pendingRapports.docs) {
      final data = doc.data();
      final file = File(data['filePath']);
      if (await file.exists()) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'rapports/rapport_${data['type']}_${DateTime.now().millisecondsSinceEpoch}.pdf');
        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        await firestore.collection('rapports').add({
          'type': data['type'],
          'date': data['date'],
          'url': downloadUrl,
          'userId': data['userId'],
          'isSynced': true,
        });
        await file.delete();
        await doc.reference.delete();
      }
    }
  } catch (e) {
    //debugPrint("❌ Error during synchronization: $e");
    rethrow;
  }
}