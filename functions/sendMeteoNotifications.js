const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function envoyerNotificationMeteo() {
  const utilisateurs = await db.collection("utilisateurs").get();
  const now = new Date().toISOString();

  for (const doc of utilisateurs.docs) {
    await db
      .collection("utilisateurs")
      .doc(doc.id)
      .collection("notifications")
      .add({
        titre: "Bulletin météo",
        message: "Aujourd’hui : temps partiellement ensoleillé. 🌤️",
        type: "meteo",
        date: now,
        lu: false
      });
  }

  console.log("✅ Notifications météo envoyées à tous les utilisateurs.");
}

envoyerNotificationMeteo();
