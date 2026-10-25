const admin = require("firebase-admin");
const fs = require("fs");

// Initialisation avec la clé du compte de service
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Charger le fichier cultures_reference.json
const data = JSON.parse(fs.readFileSync("cultures_reference.json", "utf8"));

async function importerCultures() {
  const collectionRef = db.collection("cultures_reference");

  for (const culture of data.cultures_reference) {
    try {
      const docRef = collectionRef.doc(); // Auto-ID
      await docRef.set(culture);
      console.log(`✅ Ajouté : ${culture.nom}`);
    } catch (error) {
      console.error(`❌ Erreur pour ${culture.nom} :`, error);
    }
  }

  console.log("✅ Importation terminée !");
}

importerCultures();
