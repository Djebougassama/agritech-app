const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

exports.envoiNotificationMeteo = functions.pubsub
  .schedule('every day 08:00') // Tous les jours à 08h
  .timeZone('Africa/Abidjan') // Remplace par ton fuseau si besoin
  .onRun(async (context) => {
    try {
      // 👇 Ton mock météo (ou API météo réelle)
      const meteoData = {
        titre: 'Prévision Météo',
        message: 'Aujourd’hui, risque de pluie à 40%. Prévoyez un arrosage adapté.',
        type: 'meteo',
      };

      const usersSnapshot = await admin.firestore().collection('utilisateurs').get();

      const batch = admin.firestore().batch();

      usersSnapshot.forEach((doc) => {
        const notifRef = doc.ref.collection('notifications').doc();
        batch.set(notifRef, {
          titre: meteoData.titre,
          message: meteoData.message,
          type: meteoData.type,
          date: new Date().toISOString(),
          lu: false,
        });
      });

      await batch.commit();
      console.log(' Notifications météo envoyées à tous les utilisateurs.');
    } catch (error) {
      console.error(' Erreur lors de l’envoi des notifications météo :', error);
    }
  });
