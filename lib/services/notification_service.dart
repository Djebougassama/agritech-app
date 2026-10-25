import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceNotifications {
  static final CollectionReference notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  static Future<void> _ajouterNotification({
    required String userId,
    required String titre,
    required String message,
    required String type, // 'stock', 'culture', etc.
  }) async {
    final notification = {
      'userId': userId,
      'titre': titre,
      'message': message,
      'type': type,
      'date': DateTime.now().toIso8601String(),
      'lu': false,
    };

    await notificationsRef.add(notification);
  }

  static Future<void> sendNotification({
  required String userId,
  required String titre,
  required String corps,
  required String type,
}) async {
  await _ajouterNotification(
    userId: userId,
    titre: titre,
    message: corps,
    type: type,
  );
}


  // 🔴 1. Notification STOCK FAIBLE
  static Future<void> notifierStockFaible({
    required String userId,
    required String nomProduit,
    required int quantite,
  }) async {
    if (quantite <= 5) {
      await _ajouterNotification(
        userId: userId,
        titre: 'Stock faible',
        message: 'Le produit "$nomProduit" est presque épuisé (quantité : $quantite).',
        type: 'stock',
      );
    }
  }

  // 🟢 2. Notification NOUVELLE CULTURE
  static Future<void> notifierNouvelleCulture({
    required String userId,
    required String nomCulture,
  }) async {
    await _ajouterNotification(
      userId: userId,
      titre: 'Nouvelle culture',
      message: 'La culture "$nomCulture" a été ajoutée avec succès.',
      type: 'recolte',
    );
  }

  // 🟡 3. Notification NOUVELLE VENTE
  static Future<void> notifierNouvelleVente({
    required String userId,
    required String produit,
    required double montant,
  }) async {
    await _ajouterNotification(
      userId: userId,
      titre: 'Nouvelle vente',
      message: 'Vous avez vendu "$produit" pour ${montant.toStringAsFixed(2)} GNF.',
      type: 'produit',
    );
  }

  static Future<void> notifierProduitVendu({
  required String userId,
  required String produit,
}) async {
  await _ajouterNotification(
    userId: userId,
    titre: 'Transaction effectuée',
    message: 'Une transaction a été effectuée pour votre produit "$produit".',
    type: 'produit',
  );
}

static Future<void> notifierPaiementEnAttente({
  required String userId,
  required String produit,
}) async {
  await _ajouterNotification(
    userId: userId,
    titre: 'Paiement en attente',
    message: 'Un paiement pour le produit "$produit" est en attente de confirmation.',
    type: 'transaction',
  );
}

static Future<void> notifierRuptureStock({
  required String userId,
  required String produit,
}) async {
  await _ajouterNotification(
    userId: userId,
    titre: 'Produit en rupture de stock',
    message: 'Le stock du produit "$produit" est épuisé.',
    type: 'stock',
  );
}


static Future<void> notifierProduitMisAJour({
  required String userId,
  required String produit,
}) async {
  await _ajouterNotification(
    userId: userId,
    titre: 'Produit mis à jour',
    message: 'Le produit "$produit" a été mis à jour avec succès.',
    type: 'produit',
  );
}


  // 🟠 4. Notification TRANSACTION
  static Future<void> notifierTransaction({
    required String userId,
    required double montant,
    required String moyenPaiement,
  }) async {
    await _ajouterNotification(
      userId: userId,
      titre: 'Paiement reçu',
      message: 'Une transaction de ${montant.toStringAsFixed(2)} GNF a été effectuée via $moyenPaiement.',
      type: 'transaction',
    );
  }

  // 🔵 5. Notification FORMATION
  static Future<void> notifierNouvelleFormation({
    required String userId,
    required String titreFormation,
  }) async {
    await _ajouterNotification(
      userId: userId,
      titre: 'Nouvelle formation disponible',
      message: 'Inscrivez-vous à la formation "$titreFormation" maintenant.',
      type: 'formation',
    );
  }

  // 🟢 6. Notification CONSEIL
  static Future<void> notifierNouveauConseil({
    required String userId,
    required String categorie,
  }) async {
    await _ajouterNotification(
      userId: userId,
      titre: 'Nouveau conseil ($categorie)',
      message: 'Un nouveau conseil est disponible dans la catégorie "$categorie".',
      type: 'conseil',
    );
  }

  // 🌤️ 7. Notification MÉTÉO
  static Future<void> notifierMeteo({
    required String userId,
    required String condition,
  }) async {
    await _ajouterNotification(
      userId: userId,
      titre: 'Météo : $condition',
      message: 'Prévision météo : $condition. Pensez à adapter vos activités.',
      type: 'meteo',
    );
  }

  // 🔁 Rappel d’arrosage
static Future<void> notifierRappelCultureArrosage({
  required String userId,
  required String culture,
  required DateTime date,
}) async {
  await notificationsRef.add({
    'userId': userId,
    'titre': '💧 Arrosage - $culture',
    'message': 'N\'oubliez pas d\'arroser votre culture "$culture" aujourd\'hui.',
    'type': 'rappel',
    'date': date.toIso8601String(),
    'lu': false,
  });
}

// 🌾 Rappel de récolte
static Future<void> notifierRappelCultureRecolte({
  required String userId,
  required String culture,
  required DateTime date,
}) async {
  await notificationsRef.add({
    'userId': userId,
    'titre': '🌾 Récolte - $culture',
    'message': 'Votre culture "$culture" est prête à être récoltée !',
    'type': 'rappel',
    'date': date.toIso8601String(),
    'lu': false,
  });
}

}
