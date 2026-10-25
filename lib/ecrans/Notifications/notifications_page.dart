import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/service_authentification.dart';
import '../../services/connectivity_service.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static Future<void> ajouterNotificationAutomatique({
    required String userId,
    required String titre,
    required String message,
    required String type,
    required bool isOffline,
  }) async {
    final data = {
      'titre': titre,
      'message': message,
      'type': type,
      'date': DateTime.now().toIso8601String(),
      'lu': false,
      'userId': userId,
    };

    if (isOffline) {
      await FirebaseFirestore.instance.collection('pending_notifications').add({
        ...data,
        'isSynced': false,
      });
    } else {
      await FirebaseFirestore.instance
          .collection('utilisateurs')
          .doc(userId)
          .collection('notifications')
          .add(data);
    }
  }

  static Stream<int> getNombreNotificationsNonLues(String userId) {
    return FirebaseFirestore.instance
        .collection('utilisateurs')
        .doc(userId)
        .collection('notifications')
        .where('lu', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> migrerAnciennesNotifications() async {
    final firestore = FirebaseFirestore.instance;
    final anciennesNotifs = await firestore.collection('notifications').get();

    for (final doc in anciennesNotifs.docs) {
      final data = doc.data();
      final userId = data['userId'];
      if (userId == null) continue;

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
    }

    debugPrint("🎉 Migration terminée !");
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'formation':
        return Icons.school;
      case 'stock':
        return Icons.warning_amber;
      case 'produit':
        return Icons.inventory_2;
      case 'transaction':
        return Icons.payment;
      case 'conseil':
        return Icons.message;
      case 'arrosage':
        return Icons.water_drop;
      case 'recolte':
        return Icons.agriculture;
      case 'meteo':
        return Icons.cloud;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'formation':
        return Colors.blue[700]!;
      case 'stock':
        return Colors.red[700]!;
      case 'produit':
        return Colors.green[700]!;
      case 'transaction':
        return Colors.orange[700]!;
      case 'conseil':
        return Colors.teal[700]!;
      case 'arrosage':
        return Colors.cyan[700]!;
      case 'recolte':
        return Colors.deepPurple[700]!;
      case 'meteo':
        return Colors.lightBlue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double textScaleFactor = MediaQuery.of(context).textScaleFactor;
    final double baseFontSize = screenWidth < 360 ? 14 : 16;
    final double basePadding = screenWidth * 0.04;
    final double iconSize = baseFontSize * 1.5; // ~24-36 dp

    final _auth = ServiceAuthentification();
    final user = _auth.obtenirUtilisateurActuel();
    final userId = user?.uid;

    if (userId == null) {
      return Scaffold(
        backgroundColor: Colors.green[50],
        body: Center(
          child: Text(
            "Utilisateur non connecté",
            style: GoogleFonts.lato(
              fontSize: baseFontSize * 0.9 * textScaleFactor,
              color: Colors.green[700],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.lato(
            fontSize: baseFontSize * 1.1 * textScaleFactor,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green[700],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: baseFontSize * 1.2),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Retour',
        ),
        actions: [
          StreamBuilder<int>(
            stream: getNombreNotificationsNonLues(userId),
            builder: (context, snapshot) {
              final nb = snapshot.data ?? 0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications, size: iconSize, color: Colors.white),
                    onPressed: () {},
                    tooltip: 'Notifications',
                  ),
                  if (nb > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$nb',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontSize: baseFontSize * 0.6,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          Consumer<ConnectivityService>(
            builder: (context, connectivityService, child) {
              return IconButton(
                icon: Icon(Icons.done_all, size: iconSize, color: Colors.white),
                tooltip: 'Tout marquer comme lu',
                onPressed: () async {
                  final bool isOffline = connectivityService.isOffline;
                  try {
                    final query = await FirebaseFirestore.instance
                        .collection('utilisateurs')
                        .doc(userId)
                        .collection('notifications')
                        .where('lu', isEqualTo: false)
                        .get();

                    for (var doc in query.docs) {
                      if (isOffline) {
                        await FirebaseFirestore.instance
                            .collection('pending_notifications')
                            .add({
                          'action': 'mark_read',
                          'notificationId': doc.id,
                          'userId': userId,
                          'isSynced': false,
                        });
                      } else {
                        await doc.reference.update({'lu': true});
                      }
                    }
                    if (isOffline) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Action en attente de synchronisation"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
                    );
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ConnectivityService>(
          builder: (context, connectivityService, child) {
            final bool isOffline = connectivityService.isOffline;
            return Column(
              children: [
                if (isOffline)
                  Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Text(
                      'Hors ligne - Données locales',
                      style: GoogleFonts.lato(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: baseFontSize * 0.9 * textScaleFactor,
                      ),
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('utilisateurs')
                        .doc(userId)
                        .collection('notifications')
                        .orderBy('date', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Colors.green));
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            "Erreur: ${snapshot.error}",
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                      final notifications = snapshot.data!.docs;
                      if (notifications.isEmpty) {
                        return Center(
                          child: Text(
                            'Aucune notification.',
                            style: GoogleFonts.lato(
                              fontSize: baseFontSize * 0.9 * textScaleFactor,
                              color: Colors.green[700],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(basePadding * 2),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notif = notifications[index].data() as Map<String, dynamic>;
                          final docId = notifications[index].id;
                          final date = DateTime.tryParse(notif['date'] ?? '') ?? DateTime.now();
                          final lu = notif['lu'] ?? false;

                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            margin: EdgeInsets.symmetric(vertical: basePadding * 0.5),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: basePadding * 1.5,
                                vertical: basePadding,
                              ),
                              leading: CircleAvatar(
                                radius: baseFontSize * 1.2,
                                backgroundColor: _getColorForType(notif['type']),
                                child: Icon(
                                  _getIconForType(notif['type']),
                                  color: Colors.white,
                                  size: baseFontSize * 1.2,
                                ),
                              ),
                              title: Text(
                                notif['titre'] ?? 'Sans titre',
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.9 * textScaleFactor,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[900],
                                ),
                              ),
                              subtitle: Text(
                                '${notif['message'] ?? 'Sans message'}\n${DateFormat.yMd().add_Hm().format(date)}',
                                style: GoogleFonts.lato(
                                  fontSize: baseFontSize * 0.8 * textScaleFactor,
                                  color: Colors.green[700],
                                ),
                              ),
                              isThreeLine: true,
                              trailing: !lu
                                  ? Icon(Icons.circle, color: Colors.red, size: baseFontSize * 0.6)
                                  : null,
                              onTap: () async {
                                if (!lu) {
                                  try {
                                    if (isOffline) {
                                      await FirebaseFirestore.instance
                                          .collection('pending_notifications')
                                          .add({
                                        'action': 'mark_read',
                                        'notificationId': docId,
                                        'userId': userId,
                                        'isSynced': false,
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Action en attente de synchronisation"),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    } else {
                                      await FirebaseFirestore.instance
                                          .collection('utilisateurs')
                                          .doc(userId)
                                          .collection('notifications')
                                          .doc(docId)
                                          .update({'lu': true});
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Erreur: $e"), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
