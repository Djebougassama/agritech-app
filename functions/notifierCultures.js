const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const messaging = admin.messaging();

async function envoyerNotifications() {
  const culturesSnapshot = await db.collection('cultures').get();

  for (const doc of culturesSnapshot.docs) {
    const cultureData = doc.data();
    const nomCulture = cultureData.nom?.toLowerCase();
    const userId = cultureData.userId;
    const dateRecolte = cultureData.dateRecolte?.toDate?.() || new Date(cultureData.dateRecolte);

    if (!nomCulture || !userId) continue;

    // Récupérer les données de référence
    const refSnapshot = await db.collection('cultures_reference').where('nom', '==', nomCulture).get();
    if (refSnapshot.empty) continue;

    const refData = refSnapshot.docs[0].data();

    // 📌 Notification d’arrosage
    const freqArrosage = parseInt(refData.frequence_arrosage);
    if (freqArrosage > 0) {
      const today = new Date();
      const jourArrosage = today.getDate() % freqArrosage === 0;

      if (jourArrosage) {
        await envoyerNotification(userId, `Arrosez votre culture de ${nomCulture}`, `Pensez à arroser votre ${nomCulture} aujourd’hui selon la fréquence recommandée.`);
      }
    }

    // 📌 Notification de récolte (5 jours avant la date)
    if (dateRecolte) {
      const aujourdhui = new Date();
      const diff = Math.ceil((dateRecolte - aujourdhui) / (1000 * 60 * 60 * 24)); // différence en jours

      if (diff <= 5 && diff >= 0) {
        await envoyerNotification(userId, `Récolte imminente de ${nomCulture}`, `Il reste ${diff} jour(s) avant la récolte de votre ${nomCulture}. Préparez-vous !`);
      }
    }

    console.log(`✅ Notifications vérifiées pour : ${nomCulture}`);
  }

  console.log('🎉 Toutes les notifications ont été envoyées.');
}

async function envoyerNotification(userId, titre, message) {
  const tokensSnapshot = await db.collection('tokens').where('userId', '==', userId).get();

  if (tokensSnapshot.empty) return;

  for (const doc of tokensSnapshot.docs) {
    const token = doc.data().token;
    try {
      await messaging.send({
        token,
        notification: {
          title: titre,
          body: message,
        },
      });
      console.log(`📨 Notification envoyée à ${userId} : ${titre}`);
    } catch (error) {
      console.error(`❌ Erreur en envoyant à ${userId} :`, error);
    }
  }
}

envoyerNotifications();
